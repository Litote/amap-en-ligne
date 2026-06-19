output "bucket_id" {
  description = "ID of the artifacts S3 bucket"
  value       = aws_s3_bucket.artifacts.id
}

output "bucket_arn" {
  description = "ARN of the artifacts S3 bucket"
  value       = aws_s3_bucket.artifacts.arn
}

output "zip_s3_key" {
  description = "S3 key of the Lambda ZIP"
  value       = aws_s3_object.zip.key
}

output "zip_s3_object_version" {
  description = "Version ID of the Lambda ZIP (forces redeployment when the ZIP changes)"
  value       = aws_s3_object.zip.version_id
}
