terraform {
  required_version = ">= 1.15"

  backend "s3" {
    profile      = "fairfieldct-ai-admin"
    bucket       = "terraform-state-401429382694-us-east-1-an"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
  }
}
