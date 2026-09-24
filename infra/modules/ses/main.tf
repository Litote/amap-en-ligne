# SES v2 email identity — created only when from_email is provided and
# create_identity is true. Leave ses_from_email empty to skip SES setup (emails
# will be silently dropped). Set create_identity = false when the sender's domain
# is already a verified SES identity (managed outside this stack): SES then lets
# any address of that domain send, and an extra, never-verified address identity
# would override the domain settings and block sending.

resource "aws_sesv2_email_identity" "sender" {
  count          = var.from_email != "" && var.create_identity ? 1 : 0
  email_identity = var.from_email
  tags           = var.tags
}
