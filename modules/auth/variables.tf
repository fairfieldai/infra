variable "name" {
  description = "User pool name, e.g. fairfieldct-ai-prod"
  type        = string
}

variable "domain_name" {
  description = "Custom domain for the managed login pages, e.g. auth.example.com. Its parent domain must already have an A record."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for domain_name"
  type        = string
}

variable "relying_party_id" {
  description = "WebAuthn relying party ID for passkeys: domain_name or one of its parent domains"
  type        = string
}

variable "callback_urls" {
  description = "URLs the managed login pages may redirect to after sign-in"
  type        = list(string)
}

variable "logout_urls" {
  description = "URLs the managed login pages may redirect to after sign-out"
  type        = list(string)
}

variable "email_identity_arn" {
  description = "ARN of the SES identity Cognito sends verification and sign-in codes from"
  type        = string
}

variable "from_email_address" {
  description = "From address for Cognito email, e.g. \"Example <hello@example.com>\""
  type        = string
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}
