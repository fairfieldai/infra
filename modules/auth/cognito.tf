# Essentials is free for the first 10,000 monthly active users and is the
# lowest tier with managed login, email one-time codes, and passkeys.
resource "aws_cognito_user_pool" "this" {
  name                = var.name
  user_pool_tier      = "ESSENTIALS"
  deletion_protection = "ACTIVE"
  mfa_configuration   = "OFF"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  # Managed login always asks for a password at sign-up, so the site's /join/
  # page signs members up through the API without one. Members can sign in
  # with an emailed code, a passkey, or a password if they set one.
  sign_in_policy {
    allowed_first_auth_factors = ["PASSWORD", "EMAIL_OTP", "WEB_AUTHN"]
  }

  web_authn_configuration {
    relying_party_id  = var.relying_party_id
    user_verification = "preferred"
  }

  password_policy {
    minimum_length                   = 12
    require_lowercase                = false
    require_uppercase                = false
    require_numbers                  = false
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  email_configuration {
    email_sending_account = "DEVELOPER"
    source_arn            = var.email_identity_arn
    from_email_address    = var.from_email_address
  }

  # The organization's resource control policy denies Cognito calls from
  # outside the organization, which includes the anonymous SignUp,
  # ConfirmSignUp, and InitiateAuth calls the site's /join/ page makes for
  # passwordless sign-up. This tag is the policy's exclusion.
  tags = merge(var.tags, {
    Name                  = var.name
    "dp:exclude:identity" = "true"
  })
}

# Public client for the static site: authorization code flow with PKCE, so
# there is no client secret.
resource "aws_cognito_user_pool_client" "web" {
  name         = "${var.name}-web"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls

  explicit_auth_flows = ["ALLOW_USER_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

resource "aws_cognito_user_pool_domain" "this" {
  domain                = var.domain_name
  user_pool_id          = aws_cognito_user_pool.this.id
  certificate_arn       = aws_acm_certificate_validation.this.certificate_arn
  managed_login_version = 2
}

# Styled to match the site: branding/settings.json is Cognito's default
# settings document with the site's palette in light and dark mode, following
# the browser's color scheme. Cognito picks the fonts.
resource "aws_cognito_managed_login_branding" "web" {
  user_pool_id = aws_cognito_user_pool.this.id
  client_id    = aws_cognito_user_pool_client.web.id
  settings     = file("${path.module}/branding/settings.json")

  dynamic "asset" {
    for_each = setproduct(["FORM_LOGO", "FAVICON_SVG"], ["LIGHT", "DARK"])

    content {
      category   = asset.value[0]
      color_mode = asset.value[1]
      extension  = "SVG"
      bytes      = filebase64("${path.module}/branding/logo.svg")
    }
  }
}
