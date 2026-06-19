# SES v2 email identity — created only when from_email is provided.
# Leave ses_from_email empty to skip SES setup (emails will be silently dropped).

resource "aws_sesv2_email_identity" "sender" {
  count          = var.from_email != "" ? 1 : 0
  email_identity = var.from_email
  tags           = var.tags
}
