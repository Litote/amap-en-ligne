variable "name" {
  description = "Resource name prefix"
  type        = string
}

variable "api_gateway_url" {
  description = "API Gateway invoke URL (e.g. https://<id>.execute-api.eu-west-3.amazonaws.com)"
  type        = string
}

variable "domain_name" {
  description = "Optional custom domain served by CloudFront (e.g. amap.example.org). Leave empty to use the CloudFront default domain."
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1) for the custom domain. Required only if domain_name is set."
  type        = string
  default     = ""
}

variable "cgu_html_path" {
  description = "Absolute path to the instance-specific cgu.html file to upload to the web S3 bucket. When null (default), the Flutter build's bundled default is used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all taggable resources"
  type        = map(string)
  default     = {}
}
