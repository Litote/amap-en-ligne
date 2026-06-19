output "api_url" {
  description = "API Gateway URL"
  value       = module.api_gateway.api_url
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda.function_name
}

output "lambda_alias_arn" {
  description = "ARN of the 'live' Lambda alias"
  value       = module.lambda.alias_arn
}

output "artifacts_bucket" {
  description = "S3 bucket holding the deployed JARs"
  value       = module.storage.bucket_id
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito User Pool Client ID"
  value       = module.cognito.client_id
}

output "cognito_issuer_url" {
  description = "Cognito OIDC issuer URL (= tokens' `iss` claim)"
  value       = module.cognito.issuer_url
}

output "cognito_domain" {
  description = "Cognito Hosted UI domain"
  value       = module.cognito.domain
}

output "activation_email_topic_arn" {
  description = "ARN of the SNS topic for activation emails"
  value       = module.lambda.activation_email_topic_arn
}

output "ses_from_email" {
  description = "SES sender email address"
  value       = module.ses.from_email
}

output "push_android_platform_application_arn" {
  description = "ARN of the FCM (Android) SNS Platform Application, empty if disabled"
  value       = module.push.android_platform_application_arn
}

output "push_ios_platform_application_arn" {
  description = "ARN of the APNs (iOS) SNS Platform Application, empty if disabled"
  value       = module.push.ios_platform_application_arn
}

output "web_url" {
  description = "Public URL of the web app (CloudFront or custom domain)"
  value       = module.web.web_url
}

output "web_bucket" {
  description = "Name of the S3 bucket holding the Flutter web assets"
  value       = module.web.web_bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidations)"
  value       = module.web.cloudfront_distribution_id
}
