variable "repository" {
  description = "GitHub repository allowed to assume the deploy roles, as owner/name"
  type        = string
}

variable "environments" {
  description = "Map of GitHub Environment name to the IAM role name that jobs in that Environment may assume"
  type        = map(string)
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}
