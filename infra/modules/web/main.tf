data "aws_caller_identity" "current" {}

# ─── S3 bucket for Flutter web assets ───────────────────────────────────────

resource "aws_s3_bucket" "web" {
  bucket        = "${var.name}-web-${data.aws_caller_identity.current.account_id}"
  force_destroy = false

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "web" {
  bucket                  = aws_s3_bucket.web.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "web" {
  bucket = aws_s3_bucket.web.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ─── CloudFront OAC ──────────────────────────────────────────────────────────

resource "aws_cloudfront_origin_access_control" "web" {
  name                              = "${var.name}-web-oac"
  description                       = "OAC for ${var.name} Flutter web S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ─── CloudFront response headers policy (COOP/COEP for Flutter WASM) ─────────

resource "aws_cloudfront_response_headers_policy" "wasm" {
  name = "${var.name}-wasm-headers"

  custom_headers_config {
    items {
      header   = "Cross-Origin-Opener-Policy"
      value    = "same-origin"
      override = true
    }
    items {
      header   = "Cross-Origin-Embedder-Policy"
      value    = "require-corp"
      override = true
    }
  }
}

# ─── CloudFront distribution ─────────────────────────────────────────────────

resource "aws_cloudfront_distribution" "web" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  http_version        = "http2and3"

  # S3 origin (Flutter web assets)
  origin {
    origin_id                = "s3"
    domain_name              = aws_s3_bucket.web.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.web.id
  }

  # API Gateway origin
  origin {
    origin_id   = "apigw"
    domain_name = replace(replace(var.api_gateway_url, "https://", ""), "/", "")
    custom_origin_config {
      https_port             = 443
      http_port              = 80
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # /v1/* → API Gateway (all HTTP methods, caching disabled)
  ordered_cache_behavior {
    path_pattern     = "/v1/*"
    target_origin_id = "apigw"

    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]

    # CachingDisabled managed policy
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    # AllViewerExceptHostHeader managed policy
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"

    viewer_protocol_policy = "redirect-to-https"
    compress               = false
  }

  # /.well-known/* → API Gateway (short cache)
  ordered_cache_behavior {
    path_pattern     = "/.well-known/*"
    target_origin_id = "apigw"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 60
    max_ttl                = 60
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # /* default → S3 (Flutter web)
  default_cache_behavior {
    target_origin_id = "s3"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
    response_headers_policy_id = aws_cloudfront_response_headers_policy.wasm.id
  }

  # SPA fallback: 403/404 from S3 → serve index.html
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.domain_name != "" ? [1] : []
    content {
      acm_certificate_arn      = var.acm_certificate_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.domain_name == "" ? [1] : []
    content {
      cloudfront_default_certificate = true
    }
  }

  aliases = var.domain_name != "" ? [var.domain_name] : []

  tags = var.tags
}

# ─── S3 bucket policy granting CloudFront OAC access ─────────────────────────

data "aws_iam_policy_document" "web_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontOAC"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.web.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.web.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "web" {
  bucket = aws_s3_bucket.web.id
  policy = data.aws_iam_policy_document.web_bucket_policy.json
}

# ─── Instance-specific CGU ────────────────────────────────────────────────────
# Uploaded when cgu_html_path is provided; the deploy-web-* Makefile targets
# must exclude "cgu.html" from aws s3 sync --delete to preserve this object.

resource "aws_s3_object" "cgu" {
  count = var.cgu_html_path != null ? 1 : 0

  bucket        = aws_s3_bucket.web.id
  key           = "cgu.html"
  source        = var.cgu_html_path
  content_type  = "text/html; charset=utf-8"
  etag          = filemd5(var.cgu_html_path)
  cache_control = "max-age=3600, must-revalidate"
}
