locals {
  # GitHub Actions' app ID, so required checks only accept results from Actions.
  github_actions_integration_id = 15368

  # The built-in repository admin role.
  admin_repository_role_id = 5
}

resource "github_repository" "this" {
  name         = var.name
  description  = var.description
  homepage_url = var.homepage_url
  topics       = var.topics
  visibility   = "public"

  has_issues      = true
  has_discussions = false
  has_projects    = false
  has_wiki        = false

  # Squash only, with the pull request title as the commit subject.
  allow_merge_commit          = false
  allow_rebase_merge          = false
  allow_squash_merge          = true
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "COMMIT_MESSAGES"
  allow_auto_merge            = false
  allow_update_branch         = true
  delete_branch_on_merge      = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_vulnerability_alerts" "this" {
  repository = github_repository.this.name
  enabled    = false
}

resource "github_actions_repository_permissions" "this" {
  repository           = github_repository.this.name
  enabled              = true
  allowed_actions      = "all"
  sha_pinning_required = true
}

resource "github_repository_ruleset" "main" {
  name        = "main"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  # Admins can merge a pull request without waiting on its checks, but cannot
  # push to the default branch directly.
  bypass_actors {
    actor_id    = local.admin_repository_role_id
    actor_type  = "RepositoryRole"
    bypass_mode = "pull_request"
  }

  rules {
    deletion         = true
    non_fast_forward = true

    # No approvals required: a sole maintainer cannot approve their own pull request.
    pull_request {
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = false
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = false
      allowed_merge_methods             = ["squash"]
    }

    dynamic "required_status_checks" {
      for_each = length(var.required_checks) > 0 ? [true] : []

      content {
        strict_required_status_checks_policy = false

        dynamic "required_check" {
          for_each = var.required_checks

          content {
            context        = required_check.value
            integration_id = local.github_actions_integration_id
          }
        }
      }
    }
  }
}
