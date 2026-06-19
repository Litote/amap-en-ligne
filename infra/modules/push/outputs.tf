output "android_platform_application_arn" {
  description = "ARN of the FCM (Android) SNS platform application, or empty when disabled."
  value       = try(aws_sns_platform_application.android[0].arn, "")
}

output "ios_platform_application_arn" {
  description = "ARN of the APNs (iOS) SNS platform application, or empty when disabled."
  value       = try(aws_sns_platform_application.ios[0].arn, "")
}
