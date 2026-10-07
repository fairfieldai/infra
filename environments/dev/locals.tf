locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_partition  = data.aws_partition.current.partition
  aws_region     = data.aws_region.current.region

  hosted_zone_id = data.aws_route53_zone.selected.zone_id

  # Inbox stack managed outside Terraform by CloudFormation
  inbox_stack_name = "fairfieldct-inbox-prod"
  mail_from        = "hello@inbox.fairfieldct.ai"

  ssm_parameter_path = "/fairfieldct-ai/dev"

  site_domain_name = "dev.fairfieldct.ai"

  tags = {
    Application = "fairfieldct-ai"
    Environment = "dev"
    Terraform   = "true"
  }
}
