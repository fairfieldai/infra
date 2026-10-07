module "dns" {
  source = "../../modules/dns"

  domain_name = local.domain_name

  tags = local.tags
}

module "github_oidc" {
  source = "../../modules/github-oidc"

  repository = "fairfieldai/site"
  environments = {
    dev  = "fairfieldct-ai-dev-deploy"
    prod = "fairfieldct-ai-prod-deploy"
  }

  tags = local.tags
}
