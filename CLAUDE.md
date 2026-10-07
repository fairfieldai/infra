# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
make init                  # terraform init -upgrade
make reconfigure           # terraform init -reconfigure
make fmt                   # terraform fmt -recursive
make validate              # terraform validate (runs fmt first)
make lint                  # tflint across all environments and modules
make plan                  # terraform plan (runs validate first)
make apply                 # terraform apply
make refresh               # terraform refresh
```

Targets that run in an environment default to `ENV=global` and run from `environments/$(ENV)/`. Override with `make plan ENV=prod`.

## Architecture

Terraform for the fairfieldct.ai AWS account (401429382694, us-east-1). Three environments, each a separate Terraform root with its own state:

| Environment | Contents |
|-------------|----------|
| `global` | Account-wide resources: the `fairfieldct.ai` Route 53 hosted zone, GitHub OIDC provider, and deploy roles |
| `dev` | Static site and API at `dev.fairfieldct.ai`, sign-in at `auth.dev.fairfieldct.ai` |
| `prod` | Static site and API at `www.fairfieldct.ai`, with `fairfieldct.ai` redirecting to it; sign-in at `auth.fairfieldct.ai` |

```
environments/
  global/           # Account-wide singletons (DNS, GitHub OIDC, deploy roles)
  dev/
  prod/
modules/
  api/              # HTTP API Gateway + Rust Lambda, DynamoDB table, IAM
  auth/             # Cognito user pool, managed login domain, and app client
  discord/          # Discord interactions and webhook events Lambda, routed on the HTTP API
  dns/              # Route 53 public hosted zone
  github-environment/ # GitHub Environment, deploy rules, and Actions variables in fairfieldai/site
  github-oidc/      # GitHub Actions OIDC provider and per-environment deploy roles
  static-site/      # S3 + CloudFront + ACM static site, optional apex redirect
```

Apply `global` first: `dev` and `prod` look up its hosted zone with `data.aws_route53_zone`. The zone must also be delegated at the registrar before applying `dev` or `prod`, because the static site's ACM certificate validates through DNS.

### Key Patterns

- **File layout**: data sources go in `data.tf`, locals in `locals.tf`, the provider in `provider.tf`, and the backend and provider versions in `versions.tf`. Modules have `variables.tf`, `outputs.tf`, `versions.tf`, plus resource `.tf` files.
- **Tagging**: each environment's `local.tags` (`Application`, `Environment`, `Terraform`) is applied through the provider's `default_tags`. Modules also take a `tags` variable and set `merge(var.tags, { Name = "..." })` on their resources.
- **Hosted zone lookup**: `dev` and `prod` reference the zone managed in `global` through `local.hosted_zone_id`.
- **Dynamic ARNs**: build them from `local.aws_account_id` and `local.aws_partition`, never hardcoded.
- **Static site**: `modules/static-site` serves a private S3 bucket through CloudFront with origin access control, IPv4/IPv6, HTTP→HTTPS redirect, and an HSTS/security headers policy. A viewer-request CloudFront Function (`functions/index-rewrite.js`) maps clean URLs to `index.html` for a Next.js static export (`output: 'export'`, `trailingSlash: true`); missing pages get `/404.html`. A "coming soon" page (`placeholder/index.html`) is uploaded as `index.html` and `404.html` with `ignore_changes = all`, so a later deploy replaces it and Terraform leaves it alone. The versioned site bucket expires noncurrent versions after 7 days. When `redirect_domain_names` is set, an S3 redirect-all website bucket behind a second distribution sends those hosts to `domain_name`. One DNS-validated ACM certificate covers all hostnames.
- **API**: `modules/api` creates an HTTP API (payload format 2.0) with one `ANY /{proxy+}` route to a single `provided.al2023` arm64 Lambda; the Rust Axum app does all routing under `/api`. CloudFront sends `/api/*` to it with caching disabled and every viewer header except `Host` forwarded. Terraform deploys a placeholder `bootstrap` and ignores code changes; the separate app repo deploys the real binary. The function gets its table, SSM path, and mail settings through environment variables.
- **Auth**: `modules/auth` creates an Essentials-tier Cognito user pool (free for 10,000 monthly active users) per environment. Users sign up with email and password through managed login (v2) on a custom domain, then sign in with a password, an emailed code, or a passkey. Cognito sends email through the inbox stack's SES identity as `hello@inbox.fairfieldct.ai`. The site uses a public app client with the authorization code flow and PKCE; callback URLs are `<origin>/auth/callback/`, and dev also allows `http://localhost:3000`. The API Lambda gets `COGNITO_ISSUER` and `COGNITO_CLIENT_ID` to verify access tokens. Managed login is styled to match the site: `modules/auth/branding/settings.json` is Cognito's default settings document recolored with the site palette (light and dark, following the browser), and `branding/logo.svg` is the form logo and favicon.
- **Discord**: `modules/discord` (prod only for now) creates a second Rust Lambda for the "fairfieldct.ai bot" application and attaches `POST /api/discord/interactions` and `POST /api/discord/events` to the existing HTTP API. API Gateway picks those over `ANY /{proxy+}`, and CloudFront already forwards `/api/*` with every header and the raw body, so signature verification works. The function gets `DISCORD_APPLICATION_ID` and `DISCORD_PUBLIC_KEY` (not secret); the bot token, when needed, stays in SSM. The site repo deploys its code through `DISCORD_FUNCTION_NAME`. A second function, `…-discord-reminders`, runs on an EventBridge Scheduler cron (every 15 minutes, paused until `reminders_enabled = true`) and posts meetup announcements and reminders from Discord's scheduled events to `#announcements` through a webhook. Each run covers the interval ending at its scheduled time, so reminders post once without stored state. Both functions read the bot token from `/fairfieldct-ai/discord-bot-token`; the reminder function also reads the webhook URL from `/fairfieldct-ai/prod/discord-announcements-webhook`.
- **Discord account linking**: in prod, `modules/api`'s `discord_linking` gives the site API `DISCORD_APPLICATION_ID`, `DISCORD_REDIRECT_URI` (`https://www.fairfieldct.ai/connect/discord/callback/`), and `DISCORD_CLIENT_SECRET_PARAMETER` (`/fairfieldct-ai/prod/discord-client-secret`, created outside Terraform). Members connect Discord through Discord's Linked Roles; the API stores the link (with Discord's refresh token, so it can clear the role on disconnect) in its DynamoDB table and sets the role connection. The Discord interactions function can get and delete items in that table (`accounts_table`) to remove a link when Discord sends `APPLICATION_DEAUTHORIZED`. The prod GitHub Environment also gets `DISCORD_CLIENT_ID` for the site's runtime config.
- **Email**: the `fairfieldct-inbox-prod` CloudFormation stack (not managed here) owns SES, the `inbox.fairfieldct.ai` domain, and an AgentMail-compatible mailbox API on a Lambda function URL. `modules/api` reads that stack's outputs with `data.aws_cloudformation_stack` and passes the API base URL to the Lambda, which sends and reads mail only through that API as `hello@inbox.fairfieldct.ai`; it has no access to the stack's DynamoDB tables. Email events go to the stack's `fairfieldct-inbox-prod-events` EventBridge bus. Both dev and prod use this one stack.
- **Deploy roles**: `global` creates `fairfieldct-ai-<env>-deploy`, assumable only by `fairfieldai/site` jobs running in the matching GitHub Environment. The repo uses GitHub's immutable OIDC subject format, so the trusted `sub` is `repo:fairfieldai@338284335/site@1409002923:environment:<env>`. The roles carry no permissions of their own: `dev` and `prod` look each role up with `data.aws_iam_role`, and the `static-site` and `api` modules attach inline policies scoped to their own bucket, distribution, and function.
- **GitHub Environments**: `dev` and `prod` each manage their `fairfieldai/site` GitHub Environment with the `integrations/github` provider and set its Actions variables (`AWS_ROLE_ARN`, `AWS_REGION`, `S3_BUCKET`, `CLOUDFRONT_DISTRIBUTION_ID`, `LAMBDA_FUNCTION_NAME`, `COGNITO_DOMAIN`, `COGNITO_CLIENT_ID`, `COGNITO_ISSUER`) from their own resources. `prod` only deploys from `main` after approval. Plan and apply for `dev` and `prod` need `GITHUB_TOKEN` set, e.g. `GITHUB_TOKEN=$(gh auth token) make plan ENV=prod`.
- **Secrets**: store them as SecureString SSM parameters under `/fairfieldct-ai/<environment>/`, encrypted with the AWS managed `aws/ssm` key; never Secrets Manager. Parameters are created outside Terraform so values never land in state.
- **Bucket naming**: buckets use the S3 account-regional namespace (`bucket_namespace = "account-regional"`, name suffix `-<account>-<region>-an`).
- **AWS profile**: the backend and provider both hardcode the `fairfieldct-ai-admin` profile.

### S3 Backend

Each environment's `versions.tf` configures the S3 backend: bucket `terraform-state-401429382694-us-east-1-an` in us-east-1, key `<environment>/terraform.tfstate`, with `use_lockfile = true` for native S3 locking.

### Discord server

`scripts/discord/discord_setup.py` (a uv project with ruff, ty, and pytest configured in its `pyproject.toml`) is the source of truth for the Discord server's layout; there's no maintained Terraform provider. Each category and channel is a `ChannelSpec` in `CATEGORIES`/`CHANNELS`. Run it with `--dry-run` first. It registers `/ping` and `/meetup` (`COMMANDS`) and the Linked Roles `member` metadata (`ROLE_CONNECTION_METADATA`), creates the Member role (its Links requirement is set by hand in Discord), ensures the `#inbox` and `#announcements` webhooks (`WEBHOOKS`). It never prints webhook URLs; a newly created one goes to an owner-only `<channel>-webhook-url` file for `aws ssm put-parameter`. The bot needs Administrator while it runs, even for `--dry-run`.

### CI

`.github/workflows/ci.yml` runs on PRs targeting `main` and on `workflow_dispatch`: `terraform fmt -check`, credential-free `terraform validate` (`init -backend=false`) for every environment, `tflint --recursive` using `.tflint.hcl`, and ruff, ty, and pytest for `scripts/discord`. CI does not plan or apply; apply is done locally.

When adding an environment, add it to the `validate` matrix. GitHub Actions must be pinned to a commit SHA with a version comment, never a tag. The Terraform and TFLint versions are set in the workflow's `env` block.
