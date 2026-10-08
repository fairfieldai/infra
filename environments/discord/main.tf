module "discord_server" {
  source = "../../modules/discord-server"

  server_id = local.server_id
  ssm_path  = "/fairfieldct-ai/prod"

  tags = local.tags
}
