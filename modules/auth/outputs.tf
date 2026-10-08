output "user_pool_id" {
  description = "Cognito user pool ID"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "Cognito user pool ARN, for IAM policies"
  value       = aws_cognito_user_pool.this.arn
}

output "issuer" {
  description = "Issuer URL of the user pool's tokens"
  value       = "https://cognito-idp.${data.aws_region.current.region}.amazonaws.com/${aws_cognito_user_pool.this.id}"
}

output "client_id" {
  description = "App client ID for the static site"
  value       = aws_cognito_user_pool_client.web.id
}

output "domain_name" {
  description = "Domain of the managed login pages"
  value       = aws_cognito_user_pool_domain.this.domain
}
