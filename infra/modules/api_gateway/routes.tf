# ─── POST /v1/sync ───────────────────────────────────────────────────────────
# Authenticated — JWT validated by API Gateway + re-validated in Lambda.

resource "aws_apigatewayv2_route" "sync_post" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /v1/sync"

  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
}

# ─── Unauthenticated routes — Lambda enforces its own auth where needed ───────

# Instance discovery + deep-link well-known files
resource "aws_apigatewayv2_route" "well_known" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /.well-known/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Public read endpoints (org list, server list)
resource "aws_apigatewayv2_route" "public_get" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /v1/public/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Public write endpoints (member join requests)
resource "aws_apigatewayv2_route" "public_post" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /v1/public/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Organization creation request (unauthenticated signup flow)
resource "aws_apigatewayv2_route" "organization_requests" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /v1/organization-requests"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Producer creation request (unauthenticated signup flow)
resource "aws_apigatewayv2_route" "producer_requests" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /v1/producer-requests"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Account activation (token-based, unauthenticated)
resource "aws_apigatewayv2_route" "activate" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /v1/activate"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Admin REST — producer account search + organization export (Lambda validates JWT internally)
resource "aws_apigatewayv2_route" "admin_get" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /v1/admin/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Admin REST writes — organization import (Lambda validates JWT internally)
resource "aws_apigatewayv2_route" "admin_post" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /v1/admin/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}
