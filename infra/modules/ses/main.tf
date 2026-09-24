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

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  # When create_identity is false, from_email sends through its (externally
  # managed) verified domain identity.
  sender_domain = var.from_email != "" ? split("@", var.from_email)[1] : ""
  identity_arn = (
    var.from_email == "" ? null :
    var.create_identity ? aws_sesv2_email_identity.sender[0].arn :
    "arn:aws:ses:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:identity/${local.sender_domain}"
  )
}
