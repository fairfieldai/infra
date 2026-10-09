# Created by the old scripts/discord setup script. Delete after the first apply.

import {
  to = module.discord_server.discord_auto_moderation_rule.spam
  id = "${local.server_id}/1557465180886007959"
}

import {
  to = module.discord_server.discord_auto_moderation_rule.presets
  id = "${local.server_id}/1557465181561426082"
}

import {
  to = module.discord_server.discord_application_command.ping
  id = "${local.application_id}/1557465182371061790"
}

import {
  to = module.discord_server.discord_application_command.meetup
  id = "${local.application_id}/1557485821932732460"
}

import {
  to = module.discord_server.discord_application_role_connection_metadata.this
  id = local.application_id
}
