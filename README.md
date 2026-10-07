# fairfieldct-ai-infra

Terraform for the fairfieldct.ai AWS account (401429382694).

## Layout

- `environments/` — root modules, one state file each
  - `global` — account-wide resources: the `fairfieldct.ai` Route 53 hosted zone,
    GitHub Actions OIDC provider, and deploy roles
  - `dev` — static site and API at `dev.fairfieldct.ai`, sign-in at `auth.dev.fairfieldct.ai`
  - `prod` — static site and API at `www.fairfieldct.ai`; `fairfieldct.ai` redirects to it;
    sign-in at `auth.fairfieldct.ai`
- `modules/` — reusable modules called by the environments
  - `api` — HTTP API Gateway, Rust Lambda, DynamoDB table, and IAM role
  - `auth` — Cognito user pool, managed login domain, and app client
  - `dns` — Route 53 public hosted zone
  - `github-environment` — GitHub Environment, deploy rules, and Actions variables
  - `github-oidc` — GitHub Actions OIDC provider and deploy roles
  - `static-site` — S3 bucket, CloudFront distribution, and ACM certificate for a
    static site, with an optional S3 redirect for other hostnames

State is stored in the `terraform-state-401429382694-us-east-1-an` S3 bucket
(us-east-1) under `<environment>/terraform.tfstate`. Both the backend and the
AWS provider use the `fairfieldct-ai-admin` AWS profile.

## Usage

`ENV` selects the environment and defaults to `global`.

```sh
make init ENV=global
make plan ENV=global
make apply ENV=global
```

`dev` and `prod` also manage GitHub Environments in `fairfieldai/site`, so they
need a GitHub token:

```sh
GITHUB_TOKEN=$(gh auth token) make plan ENV=prod
```

Apply `global` first: `dev` and `prod` look up the hosted zone it creates. Delegate
the zone at the registrar (the `name_servers` output) before applying `dev` or
`prod`; their ACM certificates validate through DNS.

## Deploying from GitHub Actions

The `fairfieldai/site` repo deploys the site and API. Each workflow job sets
`environment: dev` or `environment: prod` and assumes that environment's role
with `aws-actions/configure-aws-credentials`. Terraform sets these GitHub
Environment variables for the workflows: `AWS_ROLE_ARN`, `AWS_REGION`,
`S3_BUCKET`, `CLOUDFRONT_DISTRIBUTION_ID`, `LAMBDA_FUNCTION_NAME`, `COGNITO_DOMAIN`,
`COGNITO_CLIENT_ID`, and `COGNITO_ISSUER`. The workflow
needs `permissions: id-token: write`. The `prod` Environment only accepts runs
from `main`, and each prod deploy waits for approval.

## Deploying the API

The API is a Rust Axum app built for `provided.al2023` on arm64 with
[cargo-lambda](https://www.cargo-lambda.info/). Its routes live under `/api`,
because CloudFront forwards the full path:

```sh
cargo lambda build --release --arm64 --output-format zip
aws lambda update-function-code --zip-file fileb://target/lambda/<crate>/bootstrap.zip \
  --function-name "$(terraform -chdir=environments/prod output -raw api_function_name)"
```

Secrets go in SecureString SSM parameters under `/fairfieldct-ai/<environment>/`:

```sh
aws ssm put-parameter --type SecureString --name /fairfieldct-ai/prod/<name> --value '<secret>'
```

The API sends email as `hello@inbox.fairfieldct.ai` through the mailbox API run
by the `fairfieldct-inbox-prod` CloudFormation stack. Give each environment its
own key: add it to that stack's `/messaging-webhook/prod/api-keys` parameter, then
store it where the Lambda reads it:

```sh
aws ssm put-parameter --type SecureString --name /fairfieldct-ai/prod/mail-api-key --value '<key>'
```

## Deploying the site

The site is built as a Next.js static export (`output: 'export'`,
`trailingSlash: true`). Upload it and invalidate the cache with the
environment's outputs:

```sh
aws s3 sync out/ "s3://$(terraform -chdir=environments/prod output -raw site_bucket_name)" --delete
aws cloudfront create-invalidation --paths '/*' \
  --distribution-id "$(terraform -chdir=environments/prod output -raw site_distribution_id)"
```

## CI

Pull requests to `main` run `.github/workflows/ci.yml`: `terraform fmt -check`,
`terraform validate` for each environment, and [TFLint](https://github.com/terraform-linters/tflint)
with the rules in `.tflint.hcl`. None of it needs AWS credentials. Run the same
checks locally with `make validate` and `make lint` (requires `tflint`).
