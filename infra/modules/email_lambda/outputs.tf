output "function_name" {
  value = aws_lambda_function.activation_email.function_name
}

output "alias_arn" {
  value = aws_lambda_alias.live.arn
}
