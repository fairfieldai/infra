resource "discord_category_channel" "start_here" {
  server_id = var.server_id
  name      = "Start here"
}

resource "discord_category_channel" "community" {
  server_id = var.server_id
  name      = "Community"
}

resource "discord_category_channel" "events" {
  server_id = var.server_id
  name      = "Events"
}

resource "discord_category_channel" "organizers" {
  server_id = var.server_id
  name      = "Organizers"
}

resource "discord_text_channel" "welcome_and_rules" {
  server_id   = var.server_id
  name        = "welcome-and-rules"
  category_id = discord_category_channel.start_here.id
  topic       = "Start here: community guidelines and links."
}

resource "discord_announcement_channel" "announcements" {
  server_id   = var.server_id
  name        = "announcements"
  category_id = discord_category_channel.start_here.id
  topic       = "Event news and updates from organizers."
}

resource "discord_text_channel" "introductions" {
  server_id   = var.server_id
  name        = "introductions"
  category_id = discord_category_channel.start_here.id
  topic       = "New here? Tell us who you are and what you're curious about."
}

resource "discord_text_channel" "general" {
  server_id   = var.server_id
  name        = "general"
  category_id = discord_category_channel.community.id
  topic       = "Everyday conversation about AI and our town."
}

resource "discord_text_channel" "show_and_tell" {
  server_id   = var.server_id
  name        = "show-and-tell"
  category_id = discord_category_channel.community.id
  topic       = "Share what you're building, how you built it, and what you learned."
}

resource "discord_forum_channel" "help_and_questions" {
  server_id            = var.server_id
  name                 = "help-and-questions"
  category_id          = discord_category_channel.community.id
  topic                = "Ask anything about using or building with AI. One post per question."
  default_forum_layout = "list_view"
}

resource "discord_text_channel" "resources" {
  server_id   = var.server_id
  name        = "resources"
  category_id = discord_category_channel.community.id
  topic       = "Useful links, tools, papers, and tutorials."
}

resource "discord_text_channel" "meetups" {
  server_id   = var.server_id
  name        = "meetups"
  category_id = discord_category_channel.events.id
  topic       = "Meetup logistics and follow-ups. Dates and RSVPs live in Events."
}

resource "discord_text_channel" "organizers" {
  server_id   = var.server_id
  name        = "organizers"
  category_id = discord_category_channel.organizers.id
  topic       = "Planning for organizers."
}

resource "discord_text_channel" "inbox" {
  server_id   = var.server_id
  name        = "inbox"
  category_id = discord_category_channel.organizers.id
  topic       = "New email to hello@inbox.fairfieldct.ai."
}

resource "discord_text_channel" "moderator_only" {
  server_id   = var.server_id
  name        = "moderator-only"
  category_id = discord_category_channel.organizers.id
  topic       = "Updates from Discord about this community."
}

# Discord creates the Voice Channels category and its General voice channel;
# they're left as they are and only placed in the category order.
data "discord_channel" "voice_channels" {
  server_id = var.server_id
  name      = "Voice Channels"
  type      = "category"
}

resource "discord_channel_positions" "categories" {
  server_id = var.server_id
  channel_ids = [
    discord_category_channel.start_here.id,
    discord_category_channel.community.id,
    discord_category_channel.events.id,
    data.discord_channel.voice_channels.id,
    discord_category_channel.organizers.id,
  ]
}

resource "discord_channel_positions" "start_here" {
  server_id = var.server_id
  channel_ids = [
    discord_text_channel.welcome_and_rules.id,
    discord_announcement_channel.announcements.id,
    discord_text_channel.introductions.id,
  ]
}

resource "discord_channel_positions" "community" {
  server_id = var.server_id
  channel_ids = [
    discord_text_channel.general.id,
    discord_text_channel.show_and_tell.id,
    discord_forum_channel.help_and_questions.id,
    discord_text_channel.resources.id,
  ]
}
