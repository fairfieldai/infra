variable "name" {
  description = "Name prefix for the API resources, e.g. fairfieldct-ai-prod"
  type        = string
}

variable "ssm_parameter_path" {
  description = "SSM Parameter Store path the function may read, e.g. /fairfieldct-ai/prod"
  type        = string

  validation {
    condition     = can(regex("^/[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)*$", var.ssm_parameter_path))
    error_message = "ssm_parameter_path must start with / and must not end with /."
  }
}

variable "inbox_stack_name" {
  description = "CloudFormation stack that runs the mailbox API, event bus, and mail tables"
  type        = string
}

variable "mail_from" {
  description = "Address the API sends email from through the mailbox API"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the function and API access logs"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}

variable "deploy_role_name" {
  description = "IAM role granted permission to update the function code"
  type        = string
}
