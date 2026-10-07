locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region     = data.aws_region.current.region

  bucket_name_suffix = "${local.aws_account_id}-${local.aws_region}-an"

  create_redirect = length(var.redirect_domain_names) > 0
}
