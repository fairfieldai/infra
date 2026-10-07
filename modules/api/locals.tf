locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_partition  = data.aws_partition.current.partition
  aws_region     = data.aws_region.current.region

  ssm_parameter_path_arn = "arn:${local.aws_partition}:ssm:${local.aws_region}:${local.aws_account_id}:parameter${var.ssm_parameter_path}"
}
