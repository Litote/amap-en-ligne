output "from_email" {
  value = var.from_email
}

output "identity_arn" {
  description = "ARN of the SES identity (address or domain) that sends from_email; null when SES is disabled"
  value       = local.identity_arn
}
