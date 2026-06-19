# ─── SNS Mobile Push — Platform Applications ─────────────────────────────────
# Native AWS push transport for the Lambda deployment (ADR-005). Each platform
# application is created only when its credentials are supplied, so push can be
# rolled out per platform. SNS platform applications are not taggable.

# Android — FCM HTTP v1 (AWS uses the "GCM" platform name for FCM).
resource "aws_sns_platform_application" "android" {
  count               = var.fcm_service_account_json != "" ? 1 : 0
  name                = "${var.name}-fcm"
  platform            = "GCM"
  platform_credential = var.fcm_service_account_json
}

# iOS — APNs token-based (.p8) authentication.
resource "aws_sns_platform_application" "ios" {
  count                    = var.apns_signing_key != "" ? 1 : 0
  name                     = "${var.name}-apns"
  platform                 = var.apns_sandbox ? "APNS_SANDBOX" : "APNS"
  platform_credential      = var.apns_signing_key
  platform_principal       = var.apns_signing_key_id
  apple_platform_team_id   = var.apns_team_id
  apple_platform_bundle_id = var.apns_bundle_id
}
