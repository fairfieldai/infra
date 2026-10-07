# Posts meetup announcements and reminders to #announcements. Discord's
# scheduled events are the source of truth; each run covers one interval ending
# at its scheduled time, so a reminder is posted once without stored state.
resource "aws_iam_role" "reminders" {
  name               = "${var.name}-discord-reminders"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json

  tags = merge(var.tags, {
    Name = "${var.name}-discord-reminders"
  })
}

resource "aws_iam_role_policy" "reminders" {
  name   = "${var.name}-discord-reminders"
  role   = aws_iam_role.reminders.id
  policy = data.aws_iam_policy_document.reminders.json
}

resource "aws_cloudwatch_log_group" "reminders" {
  name              = "/aws/lambda/${var.name}-discord-reminders"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "/aws/lambda/${var.name}-discord-reminders"
  })
}

resource "aws_lambda_function" "reminders" {
  function_name = "${var.name}-discord-reminders"
  role          = aws_iam_role.reminders.arn
  runtime       = "provided.al2023"
  handler       = "bootstrap"
  architectures = ["arm64"]
  memory_size   = 256
  timeout       = 30

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  environment {
    variables = {
      DISCORD_GUILD_ID                        = var.guild_id
      DISCORD_BOT_TOKEN_PARAMETER             = var.bot_token_parameter
      DISCORD_ANNOUNCEMENTS_WEBHOOK_PARAMETER = var.announcements_webhook_parameter
      REMINDER_INTERVAL_MINUTES               = tostring(var.reminder_interval_minutes)
      RUST_LOG                                = "info"
    }
  }

  logging_config {
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.reminders.name
  }

  tags = merge(var.tags, {
    Name = "${var.name}-discord-reminders"
  })

  # The site repo owns the code.
  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }

  depends_on = [aws_iam_role_policy.reminders]
}

resource "aws_iam_role" "scheduler" {
  name               = "${var.name}-discord-reminders-scheduler"
  assume_role_policy = data.aws_iam_policy_document.assume_scheduler.json

  tags = merge(var.tags, {
    Name = "${var.name}-discord-reminders-scheduler"
  })
}

resource "aws_iam_role_policy" "scheduler" {
  name   = "${var.name}-discord-reminders-scheduler"
  role   = aws_iam_role.scheduler.id
  policy = data.aws_iam_policy_document.scheduler.json
}

# Runs on interval boundaries (e.g. :00, :15, :30, :45) and passes its scheduled
# time, so retries and start-up delays don't shift the window a run covers.
resource "aws_scheduler_schedule" "reminders" {
  name                = "${var.name}-discord-reminders"
  schedule_expression = "cron(0/${var.reminder_interval_minutes} * * * ? *)"
  state               = var.reminders_enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.reminders.arn
    role_arn = aws_iam_role.scheduler.arn
    input = jsonencode({
      scheduled_time = "<aws.scheduler.scheduled-time>"
    })

    retry_policy {
      maximum_event_age_in_seconds = 300
      maximum_retry_attempts       = 2
    }
  }
}
