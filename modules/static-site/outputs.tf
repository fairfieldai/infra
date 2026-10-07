output "bucket_name" {
  description = "S3 bucket holding the site content"
  value       = aws_s3_bucket.site.id
}

output "distribution_id" {
  description = "CloudFront distribution ID serving the site, for cache invalidations"
  value       = aws_cloudfront_distribution.site.id
}

output "distribution_domain_name" {
  description = "CloudFront domain name of the site distribution"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "redirect_distribution_id" {
  description = "CloudFront distribution ID serving the redirect hostnames, or null when there are none"
  value       = one(aws_cloudfront_distribution.redirect[*].id)
}

output "certificate_arn" {
  description = "ACM certificate ARN covering the site and redirect hostnames"
  value       = aws_acm_certificate_validation.this.certificate_arn
}
