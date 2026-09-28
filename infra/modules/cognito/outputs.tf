output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "client_id" {
  description = "Cognito User Pool Client ID (public, no secret)"
  value       = aws_cognito_user_pool_client.main.id
}

output "issuer_url" {
  description = "OIDC issuer URL — matches the `iss` claim of Cognito tokens"
  value       = "https://cognito-idp.${data.aws_region.current.region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
}

output "domain" {
  description = "Cognito Hosted UI domain prefix"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "region" {
  description = "AWS region the user pool lives in"
  value       = data.aws_region.current.region
}

output "initial_owner_sub" {
  description = "Cognito sub of the initial owner user; empty string when no initial owner is configured"
  value       = var.initial_owner_email != "" ? aws_cognito_user.initial_owner[0].sub : ""
}
