locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_partition  = data.aws_partition.current.partition

  domain_name = "fairfieldct.ai"

  tags = {
    Application = "fairfieldct-ai"
    Environment = "prod"
    Terraform   = "true"
  }
}
