provider "aws" {
  profile = "fairfieldct-ai-admin"
  region  = "us-east-1"

  default_tags {
    tags = local.tags
  }
}

# Authenticates with GITHUB_TOKEN, e.g. GITHUB_TOKEN=$(gh auth token).
provider "github" {
  owner = "fairfieldai"
}
