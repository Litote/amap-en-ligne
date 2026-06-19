module "dynamo" {
  source = "./modules/dynamo"

  table_name         = var.dynamo_table_name
  protection_enabled = local.env == "prod"
  tags               = local.tags
}

module "storage" {
  source = "./modules/storage"

  name     = local.name
  zip_path = var.zip_path
  tags     = local.tags
}

module "cognito" {
  source = "./modules/cognito"

  name                        = local.name
  domain_prefix               = coalesce(var.cognito_domain_prefix, local.name)
  callback_urls               = local.callback_urls
  logout_urls                 = local.logout_urls
  initial_owner_email         = var.initial_owner_email
  initial_owner_temp_password = var.initial_owner_temp_password
  tags                        = local.tags
}

module "push" {
  source = "./modules/push"

  name                     = local.name
  fcm_service_account_json = var.fcm_service_account_json
  apns_signing_key         = var.apns_signing_key
  apns_signing_key_id      = var.apns_signing_key_id
  apns_team_id             = var.apns_team_id
  apns_bundle_id           = var.apns_bundle_id
  apns_sandbox             = var.apns_sandbox
}

module "lambda" {
  source = "./modules/lambda"

  name                                  = local.name
  jar_s3_bucket                         = module.storage.bucket_id
  jar_s3_key                            = module.storage.zip_s3_key
  jar_s3_object_version                 = module.storage.zip_s3_object_version
  handler                               = "deploy.lambda.DataLambda"
  runtime                               = "provided.al2023"
  memory_mb                             = var.lambda_memory_mb
  timeout_seconds                       = var.lambda_timeout_seconds
  log_retention_days                    = var.log_retention_days
  koin_log_level                        = var.koin_log_level
  dynamo_table_name                     = module.dynamo.table_name
  dynamo_table_arn                      = module.dynamo.table_arn
  cognito_issuer_url                    = module.cognito.issuer_url
  cognito_client_id                     = module.cognito.client_id
  cognito_user_pool_id                  = module.cognito.user_pool_id
  cognito_user_pool_arn                 = module.cognito.user_pool_arn
  instance_name                         = var.instance_name
  instance_api_url                      = var.instance_api_url
  instance_terms_url                    = local.terms_url
  push_android_enabled                  = var.fcm_service_account_json != ""
  push_ios_enabled                      = var.apns_signing_key != ""
  push_android_platform_application_arn = module.push.android_platform_application_arn
  push_ios_platform_application_arn     = module.push.ios_platform_application_arn
  tags                                  = local.tags
}

module "ses" {
  source = "./modules/ses"

  from_email = var.ses_from_email
  tags       = local.tags
}

module "email_lambda" {
  source = "./modules/email_lambda"

  name                  = local.name
  jar_s3_bucket         = module.storage.bucket_id
  jar_s3_key            = module.storage.zip_s3_key
  jar_s3_object_version = module.storage.zip_s3_object_version
  ses_from_email        = var.ses_from_email
  sns_topic_arn         = module.lambda.activation_email_topic_arn
  log_retention_days    = var.log_retention_days
  tags                  = local.tags
}

module "api_gateway" {
  source = "./modules/api_gateway"

  name                   = local.name
  lambda_invoke_arn      = module.lambda.alias_invoke_arn
  lambda_alias_arn       = module.lambda.alias_arn
  jwt_issuer_url         = module.cognito.issuer_url
  jwt_audience           = module.cognito.client_id
  log_retention_days     = var.log_retention_days
  throttling_burst_limit = var.throttling_burst_limit
  throttling_rate_limit  = var.throttling_rate_limit
  cors_allow_origins     = var.cors_allow_origins
  tags                   = local.tags
}

module "web" {
  source = "./modules/web"

  name                = local.name
  api_gateway_url     = module.api_gateway.api_url
  domain_name         = var.domain_name
  acm_certificate_arn = var.acm_certificate_arn
  cgu_html_path       = "${path.module}/instance/cgu.html"
  tags                = local.tags
}

# ─── Bootstrap Server row ────────────────────────────────────────────────────
# Seeds this instance's own Server record in DynamoDB so ActivationService and
# MemberJoinRequestService can resolve server_id for UserSettings.
# The random_id is stable as long as instance_api_url doesn't change.

resource "random_id" "server" {
  count       = var.instance_api_url != "" ? 1 : 0
  byte_length = 16
  keepers = {
    instance_api_url = var.instance_api_url
  }
}

resource "aws_dynamodb_table_item" "server" {
  count      = var.instance_api_url != "" ? 1 : 0
  table_name = module.dynamo.table_name
  hash_key   = "pk"
  range_key  = "sk"

  item = jsonencode({
    pk          = { S = "SERVER" }
    sk          = { S = random_id.server[0].hex }
    entity_type = { S = "Server" }
    name        = { S = var.instance_name }
    url         = { S = var.instance_api_url }
  })

  lifecycle {
    ignore_changes = [item]
  }
}

# ─── Bootstrap Owner row ─────────────────────────────────────────────────────
# Created only when initial_owner_email is provided, in sync with the Cognito
# user created by module.cognito. Uses the Cognito sub as the owner_id so the
# DynamoDB row can be written without a separate UUID generator.
# lifecycle.ignore_changes prevents Terraform from overwriting the row after
# the owner updates their profile through the app.

resource "aws_dynamodb_table_item" "initial_owner" {
  count      = var.initial_owner_email != "" ? 1 : 0
  table_name = module.dynamo.table_name
  hash_key   = "pk"
  range_key  = "sk"

  item = jsonencode({
    pk             = { S = "OWNER" }
    sk             = { S = module.cognito.initial_owner_sub }
    entity_type    = { S = "Owner" }
    owner_id       = { S = module.cognito.initial_owner_sub }
    first_name     = { S = "" }
    last_name      = { S = "" }
    email          = { S = var.initial_owner_email }
    account_status = { S = "ACTIVE" }
    registered_at  = { N = "0" }
    updated_at     = { N = "0" }
    user_preferences = {
      S = jsonencode({
        email_notifications_enabled = true
        push_notifications_enabled  = false
        last_updated_instant        = "1970-01-01T00:00:00Z"
      })
    }
  })

  lifecycle {
    ignore_changes  = [item]
    prevent_destroy = true
  }
}
