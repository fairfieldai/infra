variable "name" {
  description = "Repository name (without owner)"
  type        = string
}

variable "description" {
  description = "Repository description"
  type        = string
  default     = null
}

variable "homepage_url" {
  description = "Repository homepage URL"
  type        = string
  default     = null
}

variable "topics" {
  description = "Repository topics"
  type        = list(string)
  default     = []
}

variable "required_checks" {
  description = "GitHub Actions check names that must pass before a pull request merges into the default branch"
  type        = list(string)
  default     = []
}
