variable "server_id" {
  description = "ID of the Discord server (guild)"
  type        = string
}

variable "ssm_path" {
  description = "SSM path the webhook URL parameters live under, e.g. /fairfieldct-ai/prod"
  type        = string
}

variable "tags" {
  description = "Tags for the AWS resources"
  type        = map(string)
  default     = {}
}
