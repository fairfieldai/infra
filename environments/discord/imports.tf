# The server was set up by scripts/discord/discord_setup.py before this root
# existed; these adopt what it created.

import {
  to = module.discord_server.discord_role.organizer
  id = "1557456560488448190/1557465136959066153"
}

import {
  to = module.discord_server.discord_role.speaker
  id = "1557456560488448190/1557465138263498773"
}

import {
  to = module.discord_server.discord_role.member
  id = "1557456560488448190/1557536208723120282"
}

import {
  to = module.discord_server.discord_category_channel.start_here
  id = "1557465140692123708"
}

import {
  to = module.discord_server.discord_category_channel.community
  id = "1557456563424198687"
}

import {
  to = module.discord_server.discord_category_channel.events
  id = "1557465142093029567"
}

import {
  to = module.discord_server.discord_category_channel.organizers
  id = "1557465153111326822"
}

import {
  to = module.discord_server.discord_text_channel.welcome_and_rules
  id = "1557456941092053044"
}

import {
  to = module.discord_server.discord_announcement_channel.announcements
  id = "1557465158886883448"
}

import {
  to = module.discord_server.discord_text_channel.introductions
  id = "1557465159558234186"
}

import {
  to = module.discord_server.discord_text_channel.general
  id = "1557456563424198689"
}

import {
  to = module.discord_server.discord_text_channel.show_and_tell
  id = "1557465164494930000"
}

import {
  to = module.discord_server.discord_forum_channel.help_and_questions
  id = "1557465166256410754"
}

import {
  to = module.discord_server.discord_text_channel.resources
  id = "1557465167447720068"
}

import {
  to = module.discord_server.discord_text_channel.meetups
  id = "1557465168181723146"
}

import {
  to = module.discord_server.discord_text_channel.organizers
  id = "1557465168995160105"
}

import {
  to = module.discord_server.discord_text_channel.inbox
  id = "1557465169892745246"
}

import {
  to = module.discord_server.discord_text_channel.moderator_only
  id = "1557456941704282276"
}

import {
  for_each = {
    welcome_and_rules = "1557456941092053044"
    announcements     = "1557465158886883448"
  }
  to = module.discord_server.discord_channel_permission.read_only_everyone[each.key]
  id = "${each.value}/1557456560488448190"
}

import {
  for_each = {
    welcome_and_rules = "1557456941092053044"
    announcements     = "1557465158886883448"
  }
  to = module.discord_server.discord_channel_permission.read_only_organizer[each.key]
  id = "${each.value}/1557465136959066153"
}

import {
  for_each = {
    organizers_category = "1557465153111326822"
    organizers          = "1557465168995160105"
    inbox               = "1557465169892745246"
    moderator_only      = "1557456941704282276"
  }
  to = module.discord_server.discord_channel_permission.private_everyone[each.key]
  id = "${each.value}/1557456560488448190"
}

import {
  for_each = {
    organizers_category = "1557465153111326822"
    organizers          = "1557465168995160105"
    inbox               = "1557465169892745246"
    moderator_only      = "1557456941704282276"
  }
  to = module.discord_server.discord_channel_permission.private_organizer[each.key]
  id = "${each.value}/1557465136959066153"
}

import {
  to = module.discord_server.discord_server_settings.this
  id = "1557456560488448190"
}

import {
  to = module.discord_server.discord_message.rules
  id = "1557456941092053044/1557465178373750784"
}

import {
  to = module.discord_server.discord_invite.permanent
  id = "1557456941092053044/wC8UCHpXJj"
}

import {
  to = module.discord_server.discord_webhook.inbox
  id = "1557465195025272852"
}

import {
  to = module.discord_server.discord_webhook.announcements
  id = "1557485826810839120"
}

import {
  to = module.discord_server.aws_ssm_parameter.inbox_webhook
  id = "/fairfieldct-ai/prod/discord-inbox-webhook"
}

import {
  to = module.discord_server.aws_ssm_parameter.announcements_webhook
  id = "/fairfieldct-ai/prod/discord-announcements-webhook"
}
