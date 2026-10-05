output "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = module.dns.hosted_zone_id
}

output "hosted_zone_name" {
  description = "Route 53 hosted zone name"
  value       = module.dns.hosted_zone_name
}

output "name_servers" {
  description = "Authoritative name servers to set at the domain registrar"
  value       = module.dns.name_servers
}
