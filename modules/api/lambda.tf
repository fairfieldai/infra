resource "aws_iam_role" "lambda" {
  name               = "${var.name}-api"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json

  tags = merge(var.tags, {
    Name = "${var.name}-api"
  })
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.name}-api"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}-api"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "/aws/lambda/${var.name}-api"
  })
}

resource "aws_lambda_function" "this" {
  function_name = "${var.name}-api"
  role          = aws_iam_role.lambda.arn
  runtime       = "provided.al2023"
  handler       = "bootstrap"
  architectures = ["arm64"]
  memory_size   = 256
  timeout       = 15

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  environment {
    variables = merge(
      {
        TABLE_NAME             = aws_dynamodb_table.this.name
        SSM_PARAMETER_PATH     = var.ssm_parameter_path
        MAIL_API_BASE_URL      = data.aws_cloudformation_stack.inbox.outputs["ApiBaseUrl"]
        MAIL_API_KEY_PARAMETER = "${var.ssm_parameter_path}/mail-api-key"
        MAIL_FROM              = var.mail_from
        COGNITO_ISSUER         = var.cognito_issuer
        COGNITO_CLIENT_ID      = var.cognito_client_id
        RUST_LOG               = "info"
      },
      # The client secret lives under ssm_parameter_path, which the function
      # can already read.
      var.discord_linking == null ? {} : {
        DISCORD_APPLICATION_ID          = var.discord_linking.application_id
        DISCORD_REDIRECT_URI            = var.discord_linking.redirect_uri
        DISCORD_CLIENT_SECRET_PARAMETER = "${var.ssm_parameter_path}/discord-client-secret"
        DISCORD_MANAGE_ROLE_CONNECTION  = tostring(var.discord_linking.manage_role_connection)
      },
    )
  }

  logging_config {
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.lambda.name
  }

  tags = merge(var.tags, {
    Name = "${var.name}-api"
  })

  # The app repo owns the code.
  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }

  depends_on = [aws_iam_role_policy.lambda]
}
