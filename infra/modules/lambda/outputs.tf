output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.data.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.data.arn
}

output "alias_arn" {
  description = "ARN of the 'live' alias"
  value       = aws_lambda_alias.live.arn
}

output "alias_invoke_arn" {
  description = "Invoke ARN of the 'live' alias (for API Gateway)"
  value       = aws_lambda_alias.live.invoke_arn
}

output "role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda.arn
}

output "published_version" {
  description = "Number of the latest published version"
  value       = aws_lambda_function.data.version
}

output "activation_email_topic_arn" {
  description = "ARN of the SNS topic for activation emails"
  value       = aws_sns_topic.activation_email.arn
}
