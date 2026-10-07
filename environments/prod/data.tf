data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

# Created by environments/global
data "aws_route53_zone" "selected" {
  name = "fairfieldct.ai"
}

# Created by environments/global
data "aws_iam_role" "deploy" {
  name = "fairfieldct-ai-prod-deploy"
}

# Created by environments/dev
data "aws_dynamodb_table" "dev_api" {
  name = "fairfieldct-ai-dev"
}
