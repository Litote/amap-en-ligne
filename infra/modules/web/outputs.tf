output "web_url" {
  description = "Public URL of the web app (CloudFront or custom domain)"
  value       = "https://${var.domain_name != "" ? var.domain_name : aws_cloudfront_distribution.web.domain_name}"
}

output "web_bucket" {
  description = "Name of the S3 bucket holding the Flutter web assets"
  value       = aws_s3_bucket.web.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidations)"
  value       = aws_cloudfront_distribution.web.id
}
