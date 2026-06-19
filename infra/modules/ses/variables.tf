variable "from_email" {
  description = "Email address used as SES sender (must be verified). Leave empty to disable SES identity creation."
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
