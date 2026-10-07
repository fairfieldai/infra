variable "repository" {
  description = "Repository name (without owner) the environment belongs to"
  type        = string
}

variable "environment" {
  description = "GitHub Environment name"
  type        = string
}

variable "variables" {
  description = "Environment variables to set, by name"
  type        = map(string)
}

variable "reviewer_user_ids" {
  description = "GitHub user IDs that must approve deployments. Empty means no approval."
  type        = list(number)
  default     = []
}

variable "deployment_branches" {
  description = "Branch name patterns allowed to deploy. Empty means any branch."
  type        = list(string)
  default     = []
}
