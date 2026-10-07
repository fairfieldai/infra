variable "name" {
  description = "Name prefix for the Discord resources, e.g. fairfieldct-ai-prod"
  type        = string
}

variable "api_id" {
  description = "HTTP API to attach the Discord routes to"
  type        = string
}

variable "api_execution_arn" {
  description = "Execution ARN of the HTTP API, for the Lambda invoke permission"
  type        = string
}

variable "application_id" {
  description = "Discord application ID"
  type        = string
}

variable "public_key" {
  description = "Discord application public key (hex), used to verify request signatures. Not a secret."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{64}$", var.public_key))
    error_message = "public_key must be the 64-character hex Ed25519 key from the Discord developer portal."
  }
}

variable "deploy_role_name" {
  description = "IAM role granted permission to update the function code"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the function"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}

variable "guild_id" {
  description = "Discord server (guild) ID the bot serves"
  type        = string
}

variable "bot_token_parameter" {
  description = "SecureString SSM parameter holding the bot token"
  type        = string
}

variable "announcements_webhook_parameter" {
  description = "SecureString SSM parameter holding the #announcements webhook URL that meetup reminders post to"
  type        = string
}

variable "reminder_interval_minutes" {
  description = "How often the meetup reminder job runs. Each run covers exactly one interval, so every reminder posts once."
  type        = number
  default     = 15

  validation {
    condition     = contains([5, 10, 15, 20, 30], var.reminder_interval_minutes)
    error_message = "reminder_interval_minutes must divide an hour evenly: 5, 10, 15, 20, or 30."
  }
}

variable "reminders_enabled" {
  description = "Whether the reminder schedule runs. Enable once the reminder code is deployed and the webhook parameter exists."
  type        = bool
  default     = false
}

variable "accounts_tables" {
  description = "DynamoDB tables holding Discord account links (the site API's, in every environment that links accounts). When Discord reports the app was deauthorized, the interactions function removes that Discord account's link from each."
  type = list(object({
    name = string
    arn  = string
  }))
}
