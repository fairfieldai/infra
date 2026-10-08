output "invite_url" {
  description = "Permanent invite to the server"
  value       = discord_invite.permanent.url
}

output "role_ids" {
  description = "Role IDs by role"
  value = {
    organizer = discord_role.organizer.id
    speaker   = discord_role.speaker.id
    member    = discord_role.member.id
  }
}
