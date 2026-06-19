variable "name" {
  description = "Naming prefix (project-env)"
  type        = string
}

variable "domain_prefix" {
  description = "Cognito Hosted UI domain prefix (must be unique within the region)"
  type        = string
}

variable "callback_urls" {
  description = "Allowed OAuth2 callback URLs for the client (mobile + web)"
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "Allowed OAuth2 logout URLs"
  type        = list(string)
  default     = []
}

variable "groups" {
  description = "Cognito groups to create (aligned with the Role enum on the back side)"
  type        = list(string)
  default     = ["OWNER", "ADMIN", "PRODUCER", "COORDINATOR", "VOLUNTEER"]
}

variable "api_scopes" {
  description = "OAuth2 scopes exposed by the resource server (must match the Scope enum on the back side)"
  type = list(object({
    name        = string
    description = string
  }))
  default = [
    { name = "read:profile", description = "Read profile information" },
    { name = "write:profile", description = "Update profile information" },
    { name = "read:deliveries", description = "Read deliveries" },
    { name = "write:deliveries", description = "Write deliveries" },
    { name = "manage:deliveries", description = "Manage deliveries" },
  ]
}

variable "access_token_validity_hours" {
  description = "Access token validity duration (hours)"
  type        = number
  default     = 1
}

variable "id_token_validity_hours" {
  description = "ID token validity duration (hours)"
  type        = number
  default     = 1
}

variable "refresh_token_validity_days" {
  description = "Refresh token validity duration (days)"
  type        = number
  default     = 30
}

variable "initial_owner_email" {
  description = "Email of the first owner to create at bootstrap. Empty = no initial user."
  type        = string
  default     = ""
}

variable "initial_owner_temp_password" {
  description = "Password of the first owner (must satisfy the policy: 12 chars, upper, lower, digit). The user can sign in directly without a change challenge."
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "AWS tags applied to the Cognito resources"
  type        = map(string)
  default     = {}
}
