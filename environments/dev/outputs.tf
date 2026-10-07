output "site_bucket_name" {
  description = "S3 bucket holding the site content"
  value       = module.site.bucket_name
}

output "site_distribution_id" {
  description = "CloudFront distribution ID serving the site, for cache invalidations"
  value       = module.site.distribution_id
}

output "site_distribution_domain_name" {
  description = "CloudFront domain name of the site distribution"
  value       = module.site.distribution_domain_name
}

output "certificate_arn" {
  description = "ACM certificate ARN for the site"
  value       = module.site.certificate_arn
}

output "api_function_name" {
  description = "Lambda function name, for deploying the API with update-function-code"
  value       = module.api.function_name
}

output "api_table_name" {
  description = "DynamoDB table used by the API"
  value       = module.api.table_name
}
