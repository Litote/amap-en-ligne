variable "name" {
  description = "Base name for SNS Platform Application resources."
  type        = string
}

# ─── FCM (Android) ────────────────────────────────────────────────────────────
# Service-account JSON for FCM HTTP v1. When empty, the Android platform
# application is not created and Android push stays disabled.

variable "fcm_service_account_json" {
  description = "FCM HTTP v1 service-account JSON used as the SNS platform credential. Empty disables Android push."
  type        = string
  default     = ""
  sensitive   = true
}

# ─── APNs (iOS) ────────────────────────────────────────────────────────────────
# Token-based (.p8) APNs auth. When the signing key is empty, the iOS platform
# application is not created and iOS push stays disabled.

variable "apns_signing_key" {
  description = "APNs token-based signing key (.p8 contents). Empty disables iOS push."
  type        = string
  default     = ""
  sensitive   = true
}

variable "apns_signing_key_id" {
  description = "APNs signing key ID (the .p8 key identifier)."
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
  description = "Use the APNs sandbox environment (development builds) instead of production."
  type        = bool
  default     = false
}
