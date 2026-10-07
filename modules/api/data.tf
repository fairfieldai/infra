data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

# Terraform only creates the function; the app repo deploys the real Rust
# binary with `aws lambda update-function-code`.
data "aws_cloudformation_stack" "inbox" {
  name = var.inbox_stack_name
}

data "archive_file" "placeholder" {
  type        = "zip"
  source_file = "${path.module}/placeholder/bootstrap"
  output_path = "${path.module}/.build/placeholder.zip"
}

data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid       = "WriteLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }

  statement {
    sid = "ReadWriteTable"
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:ConditionCheckItem",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:UpdateItem",
    ]
    resources = [
      aws_dynamodb_table.this.arn,
      "${aws_dynamodb_table.this.arn}/index/*",
    ]
  }

  # SecureString parameters encrypted with the AWS managed aws/ssm key need no
  # KMS grant; its key policy already allows decryption through SSM.
  statement {
    sid     = "ReadParameters"
    actions = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
    resources = [
      local.ssm_parameter_path_arn,
      "${local.ssm_parameter_path_arn}/*",
    ]
  }
}
