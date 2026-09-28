variable "from_email" {
  description = "Email address used as SES sender (must be verified). Leave empty to disable SES identity creation."
  type        = string
  default     = ""
}

variable "create_identity" {
  description = "Create an SES email-address identity for from_email. Set false when the sender's domain is already a verified SES identity."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
