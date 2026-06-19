output "from_email" {
  value = length(aws_sesv2_email_identity.sender) > 0 ? aws_sesv2_email_identity.sender[0].email_identity : ""
}
