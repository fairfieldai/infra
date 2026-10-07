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
