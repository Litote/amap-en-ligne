# ─── Locals ───────────────────────────────────────────────────────────────────

locals {
  # Whether any push platform is configured — derived from boolean inputs so
  # count expressions are always known at plan time (ARNs are only known after apply
  # when platform applications are created for the first time).
  push_enabled = var.push_android_enabled || var.push_ios_enabled

  # Configured SNS Mobile Push platform applications (ADR-005). May contain
  # unknown values on first apply; used only in policy content, not in count.
  push_app_arns = compact([
    var.push_android_platform_application_arn,
    var.push_ios_platform_application_arn,
  ])

  # Endpoint ARNs derived from each platform application ARN
  # (arn:aws:sns:…:app/GCM/name → arn:aws:sns:…:endpoint/GCM/name/*).
  push_endpoint_arns = [for arn in local.push_app_arns : "${replace(arn, ":app/", ":endpoint/")}/*"]

  # Push-related env vars, included only for configured platforms.
  push_env = merge(
    var.push_android_enabled ? { SNS_PLATFORM_APP_ARN_ANDROID = var.push_android_platform_application_arn } : {},
    var.push_ios_enabled ? { SNS_PLATFORM_APP_ARN_IOS = var.push_ios_platform_application_arn } : {},
  )

  # INSTANCE_TERMS_URL is optional — omitted from env when not configured.
  terms_env = var.instance_terms_url != "" ? { INSTANCE_TERMS_URL = var.instance_terms_url } : {}
}

# ─── CloudWatch Log Group ─────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.log_retention_days
}

# ─── IAM Role ─────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Minimal permissions: log writes only
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB policy: single table with 3 GSIs (by_cursor, by_organization_name, by_admin_email)
data "aws_iam_policy_document" "lambda_dynamo" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:TransactWriteItems",
    ]
    resources = [
      var.dynamo_table_arn,
      "${var.dynamo_table_arn}/index/by_cursor",
      "${var.dynamo_table_arn}/index/by_organization_name",
      "${var.dynamo_table_arn}/index/by_admin_email",
    ]
  }
}

resource "aws_iam_policy" "lambda_dynamo" {
  name   = "${var.name}-lambda-dynamo"
  policy = data.aws_iam_policy_document.lambda_dynamo.json
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_dynamo.arn
}

# Cognito admin policy: user provisioning (create/ban/delete/list users)
data "aws_iam_policy_document" "lambda_cognito" {
  statement {
    effect = "Allow"
    actions = [
      "cognito-idp:AdminCreateUser",
      "cognito-idp:AdminAddUserToGroup",
      "cognito-idp:AdminRemoveUserFromGroup",
      "cognito-idp:AdminGetUser",
      "cognito-idp:AdminUpdateUserAttributes",
      "cognito-idp:AdminSetUserPassword",
      "cognito-idp:AdminDisableUser",
      "cognito-idp:AdminEnableUser",
      "cognito-idp:AdminDeleteUser",
      "cognito-idp:AdminListGroupsForUser",
      "cognito-idp:ListUsers",
    ]
    resources = [var.cognito_user_pool_arn]
  }
}

resource "aws_iam_policy" "lambda_cognito" {
  name   = "${var.name}-lambda-cognito"
  policy = data.aws_iam_policy_document.lambda_cognito.json
}

resource "aws_iam_role_policy_attachment" "lambda_cognito" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_cognito.arn
}

# ─── Lambda Function (GraalVM native, custom runtime) ────────────────────────

resource "aws_lambda_function" "data" {
  function_name = var.name
  role          = aws_iam_role.lambda.arn

  s3_bucket         = var.jar_s3_bucket
  s3_key            = var.jar_s3_key
  s3_object_version = var.jar_s3_object_version

  handler     = var.handler
  runtime     = var.runtime
  memory_size = var.memory_mb
  timeout     = var.timeout_seconds

  publish = true

  environment {
    variables = merge({
      KOIN_LOG_LEVEL                 = var.koin_log_level
      DYNAMO_TABLE                   = var.dynamo_table_name
      COGNITO_ISSUER_URL             = var.cognito_issuer_url
      COGNITO_CLIENT_ID              = var.cognito_client_id
      COGNITO_USER_POOL_ID           = var.cognito_user_pool_id
      INSTANCE_NAME                  = var.instance_name
      INSTANCE_API_URL               = var.instance_api_url
      ACTIVATION_EMAIL_SNS_TOPIC_ARN = aws_sns_topic.activation_email.arn
    }, local.push_env, local.terms_env)
  }

  # Logs go to the log group explicitly created above
  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.basic_execution,
  ]
}

# ─── Alias "live" → published version ────────────────────────────────────────
# API Gateway targets the alias, never $LATEST

resource "aws_lambda_alias" "live" {
  name             = "live"
  function_name    = aws_lambda_function.data.function_name
  function_version = aws_lambda_function.data.version
}

# ─── SNS topic for activation emails ─────────────────────────────────────────

resource "aws_sns_topic" "activation_email" {
  name = "${var.name}-activation-email"
  tags = var.tags
}

data "aws_iam_policy_document" "lambda_sns" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.activation_email.arn]
  }
}

resource "aws_iam_policy" "lambda_sns" {
  name   = "${var.name}-lambda-sns"
  policy = data.aws_iam_policy_document.lambda_sns.json
}

resource "aws_iam_role_policy_attachment" "lambda_sns" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_sns.arn
}

# ─── SNS Mobile Push (ADR-005) ───────────────────────────────────────────────
# Only created when at least one platform application is provisioned.

data "aws_iam_policy_document" "lambda_push" {
  count = local.push_enabled ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "sns:CreatePlatformEndpoint",
      "sns:GetEndpointAttributes",
      "sns:SetEndpointAttributes",
      "sns:DeleteEndpoint",
      "sns:Publish",
    ]
    resources = concat(local.push_app_arns, local.push_endpoint_arns)
  }
}

resource "aws_iam_policy" "lambda_push" {
  count  = local.push_enabled ? 1 : 0
  name   = "${var.name}-lambda-push"
  policy = data.aws_iam_policy_document.lambda_push[0].json
}

resource "aws_iam_role_policy_attachment" "lambda_push" {
  count      = local.push_enabled ? 1 : 0
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_push[0].arn
}

# ─── Permission API Gateway → Lambda alias ───────────────────────────────────

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data.function_name
  qualifier     = aws_lambda_alias.live.name
  principal     = "apigateway.amazonaws.com"
}
