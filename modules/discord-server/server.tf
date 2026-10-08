resource "discord_server_settings" "this" {
  server_id   = var.server_id
  icon        = "data:image/png;base64,${filebase64("${path.module}/icon.png")}"
  description = "A local AI community for Fairfield, Connecticut: builders, thinkers, and the AI-curious."

  default_message_notifications = "only_mentions"
  explicit_content_filter       = "all_members"

  system_channel_id         = discord_text_channel.introductions.id
  rules_channel_id          = discord_text_channel.welcome_and_rules.id
  public_updates_channel_id = discord_text_channel.moderator_only.id
}
