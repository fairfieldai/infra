variable "domain_name" {
  description = "Hostname the site is served from, e.g. www.example.com"
  type        = string
}

variable "redirect_domain_names" {
  description = "Hostnames that permanently redirect to domain_name. Leave empty to skip the redirect bucket and distribution."
  type        = list(string)
  default     = []
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for domain_name and redirect_domain_names"
  type        = string
}

variable "bucket_name_prefix" {
  description = "Bucket name before the account-regional namespace suffix (-<account>-<region>-an)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}

variable "api_domain_name" {
  description = "Domain name of an HTTP API to serve under /api/*. Leave null to serve only static content."
  type        = string
  default     = null
}

variable "deploy_role_name" {
  description = "IAM role granted permission to upload site content and invalidate the cache"
  type        = string
}
