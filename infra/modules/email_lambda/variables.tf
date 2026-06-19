variable "name" {
  description = "Naming prefix (project-env)"
  type        = string
}

variable "jar_s3_bucket" {
  description = "S3 bucket containing the Lambda artifact"
  type        = string
}

variable "jar_s3_key" {
  description = "S3 key of the Lambda artifact"
  type        = string
}

variable "jar_s3_object_version" {
  description = "S3 object version of the artifact (forces redeployment when artifact changes)"
  type        = string
}

variable "memory_mb" {
  description = "Memory allocated to the Lambda in MB"
  type        = number
  default     = 256
}

variable "timeout_seconds" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "koin_log_level" {
  description = "Koin log level (DEBUG, INFO, WARNING, ERROR)"
  type        = string
  default     = "INFO"
}

variable "ses_from_email" {
  description = "SES verified sender email address"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic that triggers this Lambda"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
