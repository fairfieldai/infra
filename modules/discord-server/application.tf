# Slash commands the Discord Lambda in fairfieldai/site handles.
resource "discord_application_command" "ping" {
  name        = "ping"
  description = "Check that the fairfieldct.ai bot is listening"
}

resource "discord_application_command" "meetup" {
  name        = "meetup"
  description = "Show the next fairfieldct.ai meetup"
}

# Linked Roles metadata the site API sets on each member's role connection
# (fairfieldai/site, crates/api/src/discord_link.rs).
resource "discord_application_role_connection_metadata" "this" {
  records = [
    {
      type        = "boolean_equal"
      key         = "member"
      name        = "fairfieldct.ai member"
      description = "Has a fairfieldct.ai account"
    },
  ]
}
