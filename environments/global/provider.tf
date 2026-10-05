provider "aws" {
  profile = "fairfieldct-ai-admin"
  region  = "us-east-1"

  default_tags {
    tags = local.tags
  }
}
