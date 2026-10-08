locals {
  # Everyone can read these; only organizers post.
  read_only_channels = {
    welcome_and_rules = discord_text_channel.welcome_and_rules.id
    announcements     = discord_announcement_channel.announcements.id
  }

  # Only organizers can see these.
  private_channels = {
    organizers_category = discord_category_channel.organizers.id
    organizers          = discord_text_channel.organizers.id
    inbox               = discord_text_channel.inbox.id
    moderator_only      = discord_text_channel.moderator_only.id
  }
}

resource "discord_channel_permission" "read_only_everyone" {
  for_each = local.read_only_channels

  channel_id   = each.value
  overwrite_id = var.server_id
  type         = "role"
  deny         = provider::discord::permissions(["SEND_MESSAGES", "CREATE_PUBLIC_THREADS"])
}

resource "discord_channel_permission" "read_only_organizer" {
  for_each = local.read_only_channels

  channel_id   = each.value
  overwrite_id = discord_role.organizer.id
  type         = "role"
  allow        = provider::discord::permissions(["SEND_MESSAGES"])
}

resource "discord_channel_permission" "private_everyone" {
  for_each = local.private_channels

  channel_id   = each.value
  overwrite_id = var.server_id
  type         = "role"
  deny         = provider::discord::permissions(["VIEW_CHANNEL"])
}

resource "discord_channel_permission" "private_organizer" {
  for_each = local.private_channels

  channel_id   = each.value
  overwrite_id = discord_role.organizer.id
  type         = "role"
  allow        = provider::discord::permissions(["VIEW_CHANNEL", "SEND_MESSAGES"])
}
