resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = merge(var.tags, {
    Name = "token.actions.githubusercontent.com"
  })
}

data "aws_iam_policy_document" "assume" {
  for_each = var.environments

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only jobs that run in this GitHub Environment, so its protection rules
    # gate every deploy.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${var.subject_prefix}:environment:${each.key}"]
    }
  }
}

# Permissions are attached by the environment that owns the deployed resources.
resource "aws_iam_role" "deploy" {
  for_each = var.environments

  name               = each.value
  assume_role_policy = data.aws_iam_policy_document.assume[each.key].json

  tags = merge(var.tags, {
    Name = each.value
  })
}
