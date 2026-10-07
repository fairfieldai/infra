locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_partition  = data.aws_partition.current.partition
  aws_region     = data.aws_region.current.region

  parameter_arn_prefix = "arn:${local.aws_partition}:ssm:${local.aws_region}:${local.aws_account_id}:parameter"
  bot_token_arn        = "${local.parameter_arn_prefix}${var.bot_token_parameter}"
  webhook_arn          = "${local.parameter_arn_prefix}${var.announcements_webhook_parameter}"
}
