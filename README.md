# fairfieldct-ai-infra

Terraform for the fairfieldct.ai AWS account (401429382694).

## Layout

- `environments/` — root modules, one state file each
  - `global` — account-wide resources: the `fairfieldct.ai` Route 53 hosted zone
  - `dev` — dev environment
  - `prod` — prod environment
- `modules/` — reusable modules called by the environments
  - `dns` — Route 53 public hosted zone

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

Apply `global` first: `dev` and `prod` look up the hosted zone it creates.

## CI

Pull requests to `main` run `.github/workflows/ci.yml`: `terraform fmt -check`,
`terraform validate` for each environment, and [TFLint](https://github.com/terraform-linters/tflint)
with the rules in `.tflint.hcl`. None of it needs AWS credentials. Run the same
checks locally with `make validate` and `make lint` (requires `tflint`).
