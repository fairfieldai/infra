locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_partition  = data.aws_partition.current.partition
  aws_region     = data.aws_region.current.region

  hosted_zone_id = data.aws_route53_zone.selected.zone_id

  # Inbox stack managed outside Terraform by CloudFormation
  inbox_stack_name  = "fairfieldct-inbox-prod"
  mail_from         = "hello@inbox.fairfieldct.ai"
  mail_identity_arn = "arn:${local.aws_partition}:ses:${local.aws_region}:${local.aws_account_id}:identity/inbox.fairfieldct.ai"

  ssm_parameter_path = "/fairfieldct-ai/dev"

  site_domain_name = "dev.fairfieldct.ai"

  auth_domain_name      = "auth.dev.fairfieldct.ai"
  auth_relying_party_id = "dev.fairfieldct.ai"
  # localhost lets `pnpm dev` sign in against the dev user pool.
  auth_site_origins = ["https://dev.fairfieldct.ai", "http://localhost:3000"]

  # Discord application "fairfieldct.ai bot", shared with prod.
  discord_application_id = "1557457463534686319"

  tags = {
    Application = "fairfieldct-ai"
    Environment = "dev"
    Terraform   = "true"
  }
}
