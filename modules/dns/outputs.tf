output "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.this.zone_id
}

output "hosted_zone_name" {
  description = "Route 53 hosted zone name"
  value       = aws_route53_zone.this.name
}

output "name_servers" {
  description = "Authoritative name servers for the hosted zone"
  value       = aws_route53_zone.this.name_servers
}
