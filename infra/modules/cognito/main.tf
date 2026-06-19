data "aws_region" "current" {}

# ─── User Pool ────────────────────────────────────────────────────────────────
# Aligned with the claims read by `lib:authentication/AuthenticationService`:
#   - sub                         → identity key for all entity types (owner_id,
#                                   member_id, producer_account_id); producerAccountId == sub
#                                   by invariant; organizationId is resolved from the DynamoDB
#                                   member table by AuthorizedScopeResolver, not from a JWT claim
#   - email / email_verified      → email / emailVerified
#   - given_name / family_name    → firstName / lastName
#   - locale                      → language (standard OIDC, replaces "custom:app:locale")
#   - zoneinfo                    → timezone (standard OIDC, replaces "custom:app:timezone")
#   - cognito:groups              → roles (enum Role)
#   - scope                       → scopes (enum Scope, OAuth "verb:resource" form)

resource "aws_cognito_user_pool" "main" {
  name = var.name

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  mfa_configuration = "OFF"

  user_attribute_update_settings {
    attributes_require_verification_before_update = ["email"]
  }

  # Standard OIDC attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
    string_attribute_constraints {
      min_length = 3
      max_length = 256
    }
  }

  schema {
    name                = "given_name"
    attribute_data_type = "String"
    required            = false
    mutable             = true
    string_attribute_constraints {
      min_length = 0
      max_length = 256
    }
  }

  schema {
    name                = "family_name"
    attribute_data_type = "String"
    required            = false
    mutable             = true
    string_attribute_constraints {
      min_length = 0
      max_length = 256
    }
  }

  schema {
    name                = "locale"
    attribute_data_type = "String"
    required            = false
    mutable             = true
    string_attribute_constraints {
      min_length = 0
      max_length = 32
    }
  }

  schema {
    name                = "zoneinfo"
    attribute_data_type = "String"
    required            = false
    mutable             = true
    string_attribute_constraints {
      min_length = 0
      max_length = 64
    }
  }

  tags = var.tags
}

# ─── Resource Server (custom OAuth scopes) ───────────────────────────────────
# `identifier = "api"` → scopes are emitted as "api/read:profile" etc.
# `lib:authentication/Scope.fromString` only inspects the part after the slash,
# but Cognito returns the full identifier-prefixed form, so we strip it on the
# back side via the existing space-split / fromString pipeline (it parses
# "read:profile" as READ_PROFILE; the "api/" prefix would currently be dropped
# only by stripping it explicitly — see note below).

resource "aws_cognito_resource_server" "api" {
  user_pool_id = aws_cognito_user_pool.main.id
  identifier   = "api"
  name         = "${var.name}-api"

  dynamic "scope" {
    for_each = var.api_scopes
    content {
      scope_name        = scope.value.name
      scope_description = scope.value.description
    }
  }
}

# ─── Groups ──────────────────────────────────────────────────────────────────
# Cognito emits group names as-is in `cognito:groups`. Keep them uppercase so
# `Role.fromString` matches without normalization beyond .uppercase().

resource "aws_cognito_user_group" "groups" {
  for_each     = toset(var.groups)
  name         = each.key
  user_pool_id = aws_cognito_user_pool.main.id
}

# ─── App Client ──────────────────────────────────────────────────────────────
# Public client (no secret) — suitable for the Flutter mobile + web SPA.
# Authorization Code flow with PKCE is enforced by absence of generate_secret
# combined with allowed_oauth_flows = ["code"].

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.name}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
  ]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes = concat(
    ["openid", "email", "profile"],
    [for s in var.api_scopes : "${aws_cognito_resource_server.api.identifier}/${s.name}"],
  )

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  supported_identity_providers = ["COGNITO"]

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  access_token_validity  = var.access_token_validity_hours
  id_token_validity      = var.id_token_validity_hours
  refresh_token_validity = var.refresh_token_validity_days

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  read_attributes = [
    "email",
    "email_verified",
    "given_name",
    "family_name",
    "locale",
    "zoneinfo",
  ]

  write_attributes = [
    "email",
    "given_name",
    "family_name",
    "locale",
    "zoneinfo",
  ]

  depends_on = [aws_cognito_resource_server.api]
}

# ─── Initial owner (bootstrap) ───────────────────────────────────────────────
# Created only when initial_owner_email is provided. The user must change their
# temporary password on first login (FORCE_CHANGE_PASSWORD status in Cognito).
# Pass credentials via TF_VAR_* env vars — never commit them to tfvars.

resource "aws_cognito_user" "initial_owner" {
  count        = var.initial_owner_email != "" ? 1 : 0
  user_pool_id = aws_cognito_user_pool.main.id
  username     = var.initial_owner_email

  attributes = {
    email          = var.initial_owner_email
    email_verified = true
  }

  password             = var.initial_owner_temp_password
  message_action       = "SUPPRESS"
  force_alias_creation = false

  lifecycle {
    ignore_changes  = [password]
    prevent_destroy = true
  }
}

resource "aws_cognito_user_in_group" "initial_owner" {
  count        = var.initial_owner_email != "" ? 1 : 0
  user_pool_id = aws_cognito_user_pool.main.id
  username     = aws_cognito_user.initial_owner[0].username
  group_name   = "OWNER"

  depends_on = [aws_cognito_user_group.groups]

  lifecycle {
    prevent_destroy = true
  }
}

# ─── Hosted UI domain ────────────────────────────────────────────────────────

resource "aws_cognito_user_pool_domain" "main" {
  domain       = var.domain_prefix
  user_pool_id = aws_cognito_user_pool.main.id
}

