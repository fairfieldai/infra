data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# Created by environments/global
data "aws_route53_zone" "selected" {
  name = "fairfieldct.ai"
}
