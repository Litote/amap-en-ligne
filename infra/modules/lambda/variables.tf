variable "name" {
  description = "Naming prefix (project-env)"
  type        = string
}

variable "jar_s3_bucket" {
  description = "S3 bucket holding the fat JAR"
  type        = string
}

variable "jar_s3_key" {
  description = "S3 key of the fat JAR"
  type        = string
}

variable "jar_s3_object_version" {
  description = "S3 version of the JAR (forces redeployment when the JAR changes)"
  type        = string
}

variable "handler" {
  description = "Java handler class (fully qualified)"
  type        = string
  default     = "deploy.lambda.DataLambda"
}

variable "runtime" {
  description = "Lambda runtime (provided.al2023 for the native GraalVM custom runtime)"
  type        = string
  default     = "provided.al2023"
}

variable "memory_mb" {
  description = "Memory allocated to the Lambda in MB"
  type        = number
  default     = 512
}

variable "timeout_seconds" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "CloudWatch log retention duration in days"
  type        = number
  default     = 14
}

variable "koin_log_level" {
  description = "Koin log level"
  type        = string
  default     = "INFO"
}

variable "dynamo_table_name" {
  description = "Single DynamoDB table name"
  type        = string
}

variable "dynamo_table_arn" {
  description = "ARN of the single DynamoDB table"
  type        = string
}

variable "cognito_issuer_url" {
  description = "Cognito issuer URL (= tokens' `iss` claim, read by AuthenticationService via COGNITO_ISSUER_URL)"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito Client ID (used for audience verification by AuthenticationService via COGNITO_CLIENT_ID)"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID (COGNITO_USER_POOL_ID env var — used by CognitoUserProvisioningAdapter for admin calls)"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN — scope of the admin IAM permissions"
  type        = string
}

variable "instance_name" {
  description = "Human-readable instance name (INSTANCE_NAME env var)"
  type        = string
}

variable "instance_api_url" {
  description = "Public API URL of this instance (INSTANCE_API_URL env var), e.g. https://api.amap-en-ligne.org/"
  type        = string
}

variable "instance_terms_url" {
  description = "Optional URL of the instance terms-of-service page (INSTANCE_TERMS_URL env var). Exposed in the discovery document as terms_url so the app links directly to it."
  type        = string
  default     = ""
}

variable "push_android_platform_application_arn" {
  description = "SNS platform application ARN for FCM (Android) push, or empty when disabled."
  type        = string
  default     = ""
}

variable "push_ios_platform_application_arn" {
  description = "SNS platform application ARN for APNs (iOS) push, or empty when disabled."
  type        = string
  default     = ""
}

variable "push_android_enabled" {
  description = "Whether Android push is configured (true when fcm_service_account_json is non-empty). Kept separate from the ARN so count decisions are known at plan time."
  type        = bool
  default     = false
}

variable "push_ios_enabled" {
  description = "Whether iOS push is configured (true when apns_signing_key is non-empty). Kept separate from the ARN so count decisions are known at plan time."
  type        = bool
  default     = false
}

variable "tags" {
  description = "AWS tags to apply to the resources"
  type        = map(string)
  default     = {}
}
