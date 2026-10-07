module "dns" {
  source = "../../modules/dns"

  domain_name = local.domain_name

  tags = local.tags
}

module "github_oidc" {
  source = "../../modules/github-oidc"

  # fairfieldai/site uses GitHub's immutable subject format, which identifies the
  # owner and repository by ID (gh api repos/fairfieldai/site/actions/oidc/customization/sub).
  subject_prefix = "repo:fairfieldai@338284335/site@1409002923"
  environments = {
    dev  = "fairfieldct-ai-dev-deploy"
    prod = "fairfieldct-ai-prod-deploy"
  }

  tags = local.tags
}
