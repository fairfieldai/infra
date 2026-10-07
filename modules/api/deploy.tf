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

resource "aws_iam_role_policy" "deploy" {
  name   = "${var.name}-api-deploy"
  role   = var.deploy_role_name
  policy = data.aws_iam_policy_document.deploy.json
}
