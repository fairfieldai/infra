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
| `global` | Account-wide resources: the `fairfieldct.ai` Route 53 hosted zone |
| `dev` | Dev environment (no resources yet) |
| `prod` | Prod environment (no resources yet) |

```
environments/
  global/           # Account-wide singletons (DNS)
  dev/
  prod/
modules/
  dns/              # Route 53 public hosted zone
```

Apply `global` first: `dev` and `prod` look up its hosted zone with `data.aws_route53_zone`.

### Key Patterns

- **File layout**: data sources go in `data.tf`, locals in `locals.tf`, the provider in `provider.tf`, and the backend and provider versions in `versions.tf`. Modules have `variables.tf`, `outputs.tf`, `versions.tf`, plus resource `.tf` files.
- **Tagging**: each environment's `local.tags` (`Application`, `Environment`, `Terraform`) is applied through the provider's `default_tags`. Modules also take a `tags` variable and set `merge(var.tags, { Name = "..." })` on their resources.
- **Hosted zone lookup**: `dev` and `prod` reference the zone managed in `global` through `local.hosted_zone_id`.
- **Dynamic ARNs**: build them from `local.aws_account_id` and `local.aws_partition`, never hardcoded.
- **AWS profile**: the backend and provider both hardcode the `fairfieldct-ai-admin` profile.

### S3 Backend

Each environment's `versions.tf` configures the S3 backend: bucket `terraform-state-401429382694-us-east-1-an` in us-east-1, key `<environment>/terraform.tfstate`, with `use_lockfile = true` for native S3 locking.

### CI

`.github/workflows/ci.yml` runs on PRs targeting `main` and on `workflow_dispatch`: `terraform fmt -check`, credential-free `terraform validate` (`init -backend=false`) for every environment, and `tflint --recursive` using `.tflint.hcl`. CI does not plan or apply; apply is done locally.

When adding an environment, add it to the `validate` matrix. GitHub Actions must be pinned to a commit SHA with a version comment, never a tag. The Terraform and TFLint versions are set in the workflow's `env` block.
