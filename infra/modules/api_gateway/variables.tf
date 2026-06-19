variable "name" {
  description = "Naming prefix (project-env)"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda alias (for the API GW integration)"
  type        = string
}

variable "lambda_alias_arn" {
  description = "ARN of the Lambda alias (for the source_arn permission)"
  type        = string
}

variable "jwt_issuer_url" {
  description = "OIDC issuer URL for JWT validation"
  type        = string
}

variable "jwt_audience" {
  description = "JWT audience (client_id)"
  type        = string
}

variable "log_retention_days" {
  description = "Access log retention duration in days"
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
      - Empty list → cors_configuration block not emitted, CORS disabled (same-origin deployment, prod default)
      - ["*"] → wide open (dev only)
      - explicit list → whitelist (controlled cross-origin, e.g. federation)
  EOT
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "AWS tags to apply to the resources"
  type        = map(string)
  default     = {}
}
