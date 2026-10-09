locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_partition  = data.aws_partition.current.partition

  server_id      = "1557456560488448190"
  application_id = "1557457463534686319"

  tags = {
    Application = "fairfieldct-ai"
    Environment = "prod"
    Terraform   = "true"
  }
}
