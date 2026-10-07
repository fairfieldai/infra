data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

# Terraform only creates the functions; the site repo deploys the real Rust
# binary with `aws lambda update-function-code`.
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

# SecureString parameters encrypted with the AWS managed aws/ssm key need no KMS
# grant; its key policy already allows decryption through SSM.
data "aws_iam_policy_document" "lambda" {
  statement {
    sid       = "WriteLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }

  statement {
    sid       = "ReadBotToken"
    actions   = ["ssm:GetParameter"]
    resources = [local.bot_token_arn]
  }

  # Look up and delete Discord account links when a member deauthorizes the app.
  statement {
    sid       = "RemoveAccountLinks"
    actions   = ["dynamodb:GetItem", "dynamodb:DeleteItem", "dynamodb:ConditionCheckItem"]
    resources = [for table in var.accounts_tables : table.arn]
  }
}

data "aws_iam_policy_document" "reminders" {
  statement {
    sid       = "WriteLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.reminders.arn}:*"]
  }

  statement {
    sid       = "ReadBotTokenAndWebhook"
    actions   = ["ssm:GetParameter"]
    resources = [local.bot_token_arn, local.webhook_arn]
  }
}

data "aws_iam_policy_document" "assume_scheduler" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.aws_account_id]
    }
  }
}

data "aws_iam_policy_document" "scheduler" {
  statement {
    sid       = "InvokeReminders"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.reminders.arn]
  }
}

data "aws_iam_policy_document" "deploy" {
  statement {
    sid = "UpdateFunctionCode"
    actions = [
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:UpdateFunctionCode",
    ]
    resources = [aws_lambda_function.this.arn, aws_lambda_function.reminders.arn]
  }
}
