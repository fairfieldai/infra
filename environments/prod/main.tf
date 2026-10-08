module "site" {
  source = "../../modules/static-site"

  domain_name           = local.site_domain_name
  redirect_domain_names = local.site_redirect_domain_names
  api_domain_name       = module.api.api_domain_name
  hosted_zone_id        = local.hosted_zone_id
  bucket_name_prefix    = replace(local.site_domain_name, ".", "-")

  deploy_role_name = data.aws_iam_role.deploy.name

  tags = local.tags
}

module "api" {
  source = "../../modules/api"

  name               = "fairfieldct-ai-prod"
  ssm_parameter_path = local.ssm_parameter_path
  inbox_stack_name   = local.inbox_stack_name
  mail_from          = local.mail_from
  cognito_issuer     = module.auth.issuer
  cognito_client_id  = module.auth.client_id
  site_url           = "https://${local.site_domain_name}"

  # Linked Roles: members connect their Discord account to their site account.
  discord_linking = {
    application_id = local.discord_application_id
    redirect_uri   = "https://${local.site_domain_name}/connect/discord/callback/"
    # Prod owns members' Linked Roles connection; dev only records links.
    manage_role_connection = true
  }

  deploy_role_name = data.aws_iam_role.deploy.name

  tags = local.tags
}

module "github_environment" {
  source = "../../modules/github-environment"

  repository  = "site"
  environment = "prod"

  # Prod deploys only from main, after approval by jplock.
  deployment_branches = ["main"]
  reviewer_user_ids   = [49093]

  variables = {
    AWS_ROLE_ARN                    = data.aws_iam_role.deploy.arn
    AWS_REGION                      = local.aws_region
    S3_BUCKET                       = module.site.bucket_name
    CLOUDFRONT_DISTRIBUTION_ID      = module.site.distribution_id
    LAMBDA_FUNCTION_NAME            = module.api.function_name
    COGNITO_DOMAIN                  = module.auth.domain_name
    COGNITO_CLIENT_ID               = module.auth.client_id
    COGNITO_ISSUER                  = module.auth.issuer
    DISCORD_CLIENT_ID               = local.discord_application_id
    DISCORD_FUNCTION_NAME           = module.discord.function_name
    DISCORD_REMINDERS_FUNCTION_NAME = module.discord.reminders_function_name
  }
}

module "auth" {
  source = "../../modules/auth"

  name               = "fairfieldct-ai-prod"
  domain_name        = local.auth_domain_name
  hosted_zone_id     = local.hosted_zone_id
  relying_party_id   = local.auth_relying_party_id
  callback_urls      = [for origin in local.auth_site_origins : "${origin}/auth/callback/"]
  logout_urls        = [for origin in local.auth_site_origins : "${origin}/"]
  email_identity_arn = local.mail_identity_arn
  from_email_address = "\"fairfieldct.ai\" <${local.mail_from}>"

  tags = local.tags
}

module "discord" {
  source = "../../modules/discord"

  name              = "fairfieldct-ai-prod"
  api_id            = module.api.api_id
  api_execution_arn = module.api.api_execution_arn
  application_id    = local.discord_application_id
  public_key        = local.discord_public_key
  guild_id          = local.discord_guild_id

  # Dev links the same Discord accounts but never receives Discord's webhook
  # events, so prod removes deauthorized links from both tables. The reminder
  # function also copies meetups into both, so dev shows the same events.
  site_tables = [
    { name = module.api.table_name, arn = module.api.table_arn },
    { name = data.aws_dynamodb_table.dev_api.name, arn = data.aws_dynamodb_table.dev_api.arn },
  ]

  # Only prod emails its members.
  email = {
    table_name             = module.api.table_name
    user_pool_id           = module.auth.user_pool_id
    user_pool_arn          = module.auth.user_pool_arn
    mail_api_base_url      = module.api.mail_api_base_url
    mail_api_key_parameter = module.api.mail_api_key_parameter
    mail_from              = local.mail_from
    site_url               = "https://${local.site_domain_name}"
  }

  # Created outside Terraform so the values never land in state.
  bot_token_parameter             = "/fairfieldct-ai/discord-bot-token"
  announcements_webhook_parameter = "${local.ssm_parameter_path}/discord-announcements-webhook"

  # Needs the reminder code deployed and the webhook parameter in place
  # (scripts/discord creates the webhook).
  reminders_enabled = true

  deploy_role_name = data.aws_iam_role.deploy.name

  tags = local.tags
}
