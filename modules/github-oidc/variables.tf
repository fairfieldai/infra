variable "subject_prefix" {
  description = "Prefix of the GitHub OIDC sub claim for the repository allowed to assume the deploy roles, e.g. repo:owner@<owner-id>/name@<repo-id>"
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
