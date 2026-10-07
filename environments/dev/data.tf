data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

# Created by environments/global
data "aws_route53_zone" "selected" {
  name = "fairfieldct.ai"
}

# Created by environments/global
data "aws_iam_role" "deploy" {
  name = "fairfieldct-ai-dev-deploy"
}
