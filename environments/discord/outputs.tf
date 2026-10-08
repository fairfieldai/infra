output "invite_url" {
  description = "Permanent invite to the Discord server"
  value       = module.discord_server.invite_url
}

output "role_ids" {
  description = "Discord role IDs by role"
  value       = module.discord_server.role_ids
}
