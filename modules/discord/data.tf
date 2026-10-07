# Terraform only creates the function; the site repo deploys the real Rust
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

data "aws_iam_policy_document" "lambda" {
  statement {
    sid       = "WriteLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
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
    resources = [aws_lambda_function.this.arn]
  }
}
