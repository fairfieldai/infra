resource "discord_role" "organizer" {
  server_id   = var.server_id
  name        = "Organizer"
  color       = provider::discord::color("#1d7a66")
  hoist       = true
  mentionable = true
  permissions = provider::discord::permissions([
    "MANAGE_MESSAGES",
    "MANAGE_THREADS",
    "MODERATE_MEMBERS",
    "MANAGE_EVENTS",
    "CREATE_EVENTS",
    "MENTION_EVERYONE",
  ])
}

resource "discord_role" "speaker" {
  server_id   = var.server_id
  name        = "Speaker / Demo"
  color       = provider::discord::color("#e3b23c")
  mentionable = true
}

# Granted by Discord through Linked Roles once a member connects their account
# at https://www.fairfieldct.ai/connect/discord/. Discord's API can't set a
# role's Links requirement; add "fairfieldct.ai member" to it in Server
# Settings, Roles, Member, Links.
resource "discord_role" "member" {
  server_id   = var.server_id
  name        = "Member"
  color       = provider::discord::color("#4cc3a5")
  mentionable = true
}
