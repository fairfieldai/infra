tflint {
  required_version = ">= 0.64"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.49.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Every environment declares the standard account, partition and hosted zone
# lookups in data.tf and locals.tf before any resource uses them.
rule "terraform_unused_declarations" {
  enabled = false
}
