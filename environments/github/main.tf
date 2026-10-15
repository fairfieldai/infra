module "site" {
  source = "../../modules/github-repository"

  name         = "site"
  description  = "Website and API for fairfieldct.ai, a local AI community for Fairfield, CT"
  homepage_url = "https://www.fairfieldct.ai"
  topics       = ["ai", "community", "connecticut", "fairfield", "meetup", "nextjs", "rust", "axum", "aws-lambda"]

  required_checks = ["Web", "API", "Workflows"]
}

module "infra" {
  source = "../../modules/github-repository"

  name         = "infra"
  description  = "Terraform for fairfieldct.ai: AWS hosting, DNS, sign-in, deploy access, GitHub, and Discord"
  homepage_url = "https://www.fairfieldct.ai"
  topics       = ["ai", "community", "connecticut", "terraform", "aws", "cloudfront", "cognito", "github-actions", "discord"]

  required_checks = [
    "Format",
    "Lint",
    "Validate (environments/global)",
    "Validate (environments/dev)",
    "Validate (environments/prod)",
    "Validate (environments/discord)",
    "Validate (environments/github)",
  ]
}

# The organization profile repository.
module "dot_github" {
  source = "../../modules/github-repository"

  name         = ".github"
  description  = "Organization profile for the Fairfield, CT AI Community"
  homepage_url = "https://www.fairfieldct.ai"
  topics       = ["community", "connecticut"]
}
