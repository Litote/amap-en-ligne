variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "eu-west-3"
}

variable "zip_path" {
  description = "Local path to the native Lambda ZIP produced by make build"
  type        = string
  default     = "../back/deploy/lambda/build/libs/lambda.zip"
}

variable "cognito_domain_prefix" {
  description = "Cognito Hosted UI domain prefix. Must be unique within the region. If empty, uses local.name."
  type        = string
  default     = ""
}

variable "extra_oauth_urls" {
  description = "Additional OAuth2 URLs (e.g. http://localhost:3000 for local dev) — added to the URLs derived from instance_api_url"
  type        = list(string)
  default     = []
}

variable "koin_log_level" {
  description = "Koin log level (DEBUG, INFO, WARNING, ERROR)"
  type        = string
  default     = "INFO"
}

variable "lambda_memory_mb" {
  description = "Memory allocated to the Lambda in MB"
  type        = number
  default     = 512
}

variable "lambda_timeout_seconds" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "CloudWatch log retention duration in days"
  type        = number
  default     = 14
}

variable "throttling_burst_limit" {
  description = "API Gateway burst limit"
  type        = number
  default     = 100
}

variable "throttling_rate_limit" {
  description = "API Gateway rate limit (req/s)"
  type        = number
  default     = 50
}

variable "cors_allow_origins" {
  description = <<-EOT
    Origins allowed by API Gateway for CORS.
      - Empty list → CORS disabled (same-origin deployment, prod default)
      - ["*"] → wide open (dev only)
      - explicit list → whitelist (controlled cross-origin, e.g. federation)
  EOT
  type        = list(string)
  default     = []
}

variable "dynamo_table_name" {
  description = "Single DynamoDB table name (single-table design)"
  type        = string
  default     = "data"
}

variable "ses_from_email" {
  description = "Email address for SES sender (must be verified in SES)"
  type        = string
  default     = ""
}

variable "instance_name" {
  description = "Human-readable name of this instance (shown in discovery endpoint)"
  type        = string
  default     = "amap-en-ligne"
}

variable "instance_api_url" {
  description = "Public base URL of the API (used for activation links and discovery)"
  type        = string
  default     = ""
}

# ─── Push notifications (SNS Mobile Push — ADR-005) ──────────────────────────
# Each platform is enabled only when its credentials are provided. Secrets are
# expected to come from the environment (e.g. TF_VAR_fcm_service_account_json),
# not from a committed terraform.tfvars.

variable "fcm_service_account_json" {
  description = "FCM HTTP v1 service-account JSON for Android push. Empty disables Android push."
  type        = string
  default     = ""
  sensitive   = true
}

variable "apns_signing_key" {
  description = "APNs token-based signing key (.p8 contents) for iOS push. Empty disables iOS push."
  type        = string
  default     = ""
  sensitive   = true
}

variable "apns_signing_key_id" {
  description = "APNs signing key ID."
  type        = string
  default     = ""
}

variable "apns_team_id" {
  description = "Apple Developer team ID."
  type        = string
  default     = ""
}

variable "apns_bundle_id" {
  description = "iOS app bundle identifier."
  type        = string
  default     = ""
}

variable "apns_sandbox" {
  description = "Use the APNs sandbox environment instead of production."
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Optional custom domain served by CloudFront (e.g. amap.example.org). Leave empty to use the CloudFront default domain."
  type        = string
  default     = ""
}

variable "instance_terms_url" {
  description = <<-EOT
    Optional URL of the instance terms-of-service page, exposed in the discovery document as terms_url.
    When empty (default) and domain_name is set, https://<domain_name>/cgu.html is used automatically.
    Set explicitly to override (e.g. a dedicated page on the instance website).
  EOT
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1) for the custom domain. Required only if domain_name is set."
  type        = string
  default     = ""
}

# ─── Bootstrap owner ─────────────────────────────────────────────────────────
# When set, creates the initial OWNER user in Cognito AND the corresponding
# Owner row in DynamoDB. Pass via TF_VAR_* — never commit credentials.

variable "initial_owner_email" {
  description = "Email of the first owner to create at bootstrap. Empty = no initial user."
  type        = string
  default     = ""
}

variable "initial_owner_temp_password" {
  description = "Temporary password of the first owner (12 chars min., upper, lower, digit)."
  type        = string
  default     = ""
  sensitive   = true
}
