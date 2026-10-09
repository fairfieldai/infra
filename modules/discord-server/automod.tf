# Discord's own mention-spam rule ("Block Mention Spam") is left unmanaged.

resource "discord_auto_moderation_rule" "spam" {
  server_id    = var.server_id
  name         = "Block spam content"
  event_type   = "message_send"
  trigger_type = "spam"
  enabled      = true

  actions = [{ type = "block_message", custom_message = "This message was blocked by AutoMod." }]
}

resource "discord_auto_moderation_rule" "presets" {
  server_id    = var.server_id
  name         = "Block sexual content and slurs"
  event_type   = "message_send"
  trigger_type = "keyword_preset"
  enabled      = true

  trigger_metadata = {
    presets = ["sexual_content", "slurs"]
  }

  actions = [{ type = "block_message", custom_message = "This message was blocked by AutoMod." }]
}
