module "dns" {
  source = "../../modules/dns"

  domain_name = local.domain_name

  tags = local.tags
}
