resource "aws_iam_role" "lambda" {
  name               = "${var.name}-discord"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json

  tags = merge(var.tags, {
    Name = "${var.name}-discord"
  })
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.name}-discord"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}-discord"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "/aws/lambda/${var.name}-discord"
  })
}

# Discord expects an interaction response within 3 seconds; the timeout leaves
# room for a cold start without letting a stuck request run long.
resource "aws_lambda_function" "this" {
  function_name = "${var.name}-discord"
  role          = aws_iam_role.lambda.arn
  runtime       = "provided.al2023"
  handler       = "bootstrap"
  architectures = ["arm64"]
  memory_size   = 256
  timeout       = 5

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  environment {
    variables = {
      DISCORD_APPLICATION_ID      = var.application_id
      DISCORD_PUBLIC_KEY          = var.public_key
      DISCORD_GUILD_ID            = var.guild_id
      DISCORD_BOT_TOKEN_PARAMETER = var.bot_token_parameter
      RUST_LOG                    = "info"
    }
  }

  logging_config {
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.lambda.name
  }

  tags = merge(var.tags, {
    Name = "${var.name}-discord"
  })

  # The site repo owns the code.
  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }

  depends_on = [aws_iam_role_policy.lambda]
}

resource "aws_iam_role_policy" "deploy" {
  name   = "${var.name}-discord-deploy"
  role   = var.deploy_role_name
  policy = data.aws_iam_policy_document.deploy.json
}
