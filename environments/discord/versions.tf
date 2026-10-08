terraform {
  required_version = ">= 1.15"

  backend "s3" {
    profile      = "fairfieldct-ai-admin"
    bucket       = "terraform-state-401429382694-us-east-1-an"
    key          = "discord/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    discord = {
      source  = "smoketurner/discord"
      version = "~> 0.1"
    }
  }
}
