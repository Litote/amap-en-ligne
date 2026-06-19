variable "table_name" {
  description = "Single DynamoDB table name (single-table design)"
  type        = string
}

variable "protection_enabled" {
  description = "Enables point-in-time recovery and deletion protection (prod only)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "AWS tags to apply to the resources"
  type        = map(string)
  default     = {}
}
