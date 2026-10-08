# The Lambdas post through these webhooks and read their URLs from SSM. The
# URLs are credentials, so they're in this root's state as well as SSM.
resource "discord_webhook" "inbox" {
  channel_id = discord_text_channel.inbox.id
  name       = "Inbox"
}

# Meetup announcements and reminders appear to come from the community.
resource "discord_webhook" "announcements" {
  channel_id = discord_announcement_channel.announcements.id
  name       = "fairfieldct.ai"
  avatar     = "data:image/png;base64,${filebase64("${path.module}/icon.png")}"
}

resource "aws_ssm_parameter" "inbox_webhook" {
  name  = "${var.ssm_path}/discord-inbox-webhook"
  type  = "SecureString"
  value = discord_webhook.inbox.url

  tags = merge(var.tags, { Name = "${var.ssm_path}/discord-inbox-webhook" })
}

resource "aws_ssm_parameter" "announcements_webhook" {
  name  = "${var.ssm_path}/discord-announcements-webhook"
  type  = "SecureString"
  value = discord_webhook.announcements.url

  tags = merge(var.tags, { Name = "${var.ssm_path}/discord-announcements-webhook" })
}
