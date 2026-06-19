data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ─── CloudWatch Log Group for API Gateway access logs ────────────────────────

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/apigateway/${var.name}-access"
  retention_in_days = var.log_retention_days
}

# ─── HTTP API v2 ──────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_api" "main" {
  name          = var.name
  protocol_type = "HTTP"
  description   = "HTTP API Gateway for ${var.name}"

  dynamic "cors_configuration" {
    for_each = length(var.cors_allow_origins) > 0 ? [1] : []
    content {
      allow_origins = var.cors_allow_origins
      allow_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
      allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key"]
      max_age       = 300
    }
  }
}

# ─── Native JWT Authorizer ───────────────────────────────────────────────────
# Cognito access tokens carry `client_id` (not `aud`); HTTP API v2 matches
# `audience` against `client_id` in that case, so we pass the Cognito client ID
# as the audience entry.

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.name}-jwt-authorizer"
  jwt_configuration {
    issuer   = var.jwt_issuer_url
    audience = [var.jwt_audience]
  }
}

# ─── Lambda proxy integration ────────────────────────────────────────────────

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_invoke_arn
  payload_format_version = "2.0" # Format APIGatewayV2HTTPEvent (payload v2)
  timeout_milliseconds   = 29000 # Slightly below the Lambda timeout
}

# ─── $default stage with auto-deploy and access logs ────────────────────────

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
      errorMessage     = "$context.error.message"
      integrationError = "$context.integrationErrorMessage"
    })
  }

  default_route_settings {
    throttling_burst_limit   = var.throttling_burst_limit
    throttling_rate_limit    = var.throttling_rate_limit
    detailed_metrics_enabled = true
    logging_level            = "INFO"
  }
}

# ─── source_arn permission for the Lambda ────────────────────────────────────
# Restricts invocations to this API Gateway only

resource "aws_lambda_permission" "api_gateway_source" {
  statement_id  = "AllowAPIGatewayInvokeFromThisAPI"
  action        = "lambda:InvokeFunction"
  function_name = split(":", var.lambda_alias_arn)[6]
  qualifier     = split(":", var.lambda_alias_arn)[7]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
