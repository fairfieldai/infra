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
    AWS_ROLE_ARN               = data.aws_iam_role.deploy.arn
    AWS_REGION                 = local.aws_region
    S3_BUCKET                  = module.site.bucket_name
    CLOUDFRONT_DISTRIBUTION_ID = module.site.distribution_id
    LAMBDA_FUNCTION_NAME       = module.api.function_name
    COGNITO_DOMAIN             = module.auth.domain_name
    COGNITO_CLIENT_ID          = module.auth.client_id
    COGNITO_ISSUER             = module.auth.issuer
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
