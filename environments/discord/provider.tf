provider "aws" {
  profile = "fairfieldct-ai-admin"
  region  = "us-east-1"

  default_tags {
    tags = local.tags
  }
}

# Authenticates with DISCORD_TOKEN, the bot token in /fairfieldct-ai/discord-bot-token.
provider "discord" {}
