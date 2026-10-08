# The code of conduct in #welcome-and-rules. Links are wrapped in <...> so
# Discord doesn't show previews for them.
resource "discord_message" "rules" {
  channel_id = discord_text_channel.welcome_and_rules.id
  content = chomp(templatefile("${path.module}/rules.md.tftpl", {
    introductions      = discord_text_channel.introductions.id
    show_and_tell      = discord_text_channel.show_and_tell.id
    help_and_questions = discord_forum_channel.help_and_questions.id
    announcements      = discord_announcement_channel.announcements.id
  }))
}

resource "discord_invite" "permanent" {
  channel_id = discord_text_channel.welcome_and_rules.id
  max_age    = 0
  max_uses   = 0
}
