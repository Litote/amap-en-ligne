output "api_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.main.id
}

output "api_url" {
  description = "API Gateway URL (public endpoint)"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_arn" {
  description = "API Gateway ARN"
  value       = aws_apigatewayv2_api.main.arn
}

output "execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_apigatewayv2_api.main.execution_arn
}
