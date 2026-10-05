variable "domain_name" {
  description = "Domain name of the public hosted zone"
  type        = string
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}
