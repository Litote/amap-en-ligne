output "table_name" {
  description = "Single DynamoDB table name"
  value       = aws_dynamodb_table.main.name
}

output "table_arn" {
  description = "ARN of the single DynamoDB table"
  value       = aws_dynamodb_table.main.arn
}
