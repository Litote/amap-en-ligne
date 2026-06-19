locals {
  env     = terraform.workspace
  project = "amap-en-ligne"
  name    = "${local.project}-${local.env}"

  tags = {
    Project     = local.project
    Environment = local.env
    ManagedBy   = "terraform"
  }

  callback_urls = concat(
    ["${var.instance_api_url}/callback"],
    var.extra_oauth_urls,
  )
  logout_urls = concat(
    [var.instance_api_url],
    var.extra_oauth_urls,
  )

  # Derived terms URL: explicit override > https://<domain_name>/cgu.html > "" (omitted)
  terms_url = var.instance_terms_url != "" ? var.instance_terms_url : (
    var.domain_name != "" ? "https://${var.domain_name}/cgu.html" : ""
  )
}
