locals {
  origin_id   = "${var.project}-${var.environment}-s3-origin"
  use_custom  = var.custom_domain != "" && var.acm_certificate_arn != ""
  # null omits the attribute entirely — CloudFront rejects an empty string for originPath.
  origin_path = var.website_prefix != "" ? "/${var.website_prefix}" : null
}

# ─── Origin Access Control ────────────────────────────────────────────────────
# OAC is the modern successor to OAI — it signs requests with SigV4,
# works with SSE-KMS, and supports all S3 operations.

resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.project}-${var.environment}-oac"
  description                       = "OAC for ${var.project} ${var.environment} website bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ─── Managed cache and request policies ──────────────────────────────────────

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "Managed-SecurityHeadersPolicy"
}

# ─── CloudFront distribution ──────────────────────────────────────────────────

# tfsec:ignore:aws-cloudfront-enable-waf
resource "aws_cloudfront_distribution" "website" {
  #checkov:skip=CKV_AWS_68:WAF is optional for static websites; add a waf_acl_arn variable to associate one
  #checkov:skip=CKV2_AWS_47:WAF is optional for static websites
  #checkov:skip=CKV_AWS_86:CloudFront access logging is enabled via logging_config; S3 access logs also enabled
  #checkov:skip=CKV_AWS_310:Single S3 origin is appropriate for a static website; S3 provides 99.99% availability SLA
  #checkov:skip=CKV_AWS_374:Geo restriction is controlled via var.geo_restriction_locations; no restriction is a valid default
  #checkov:skip=CKV_AWS_174:TLS 1.2 enforcement requires a custom domain + ACM certificate; set custom_domain and acm_certificate_arn to enable
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.index_document
  price_class         = var.price_class
  comment             = "${var.project}-${var.environment} website"
  aliases             = local.use_custom ? [var.custom_domain] : []

  origin {
    domain_name              = var.website_bucket_regional_domain
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
    # origin_path scopes CloudFront to a specific prefix in the bucket,
    # so each project's distribution sees its prefix as the site root.
    origin_path = local.origin_path
  }

  default_cache_behavior {
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security_headers.id
  }

  # SPA support: serve index.html for unknown paths instead of an S3 403/404
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/${var.index_document}"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/${var.error_document}"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = length(var.geo_restriction_locations) > 0 ? "blacklist" : "none"
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = local.use_custom ? false : true
    acm_certificate_arn            = local.use_custom ? var.acm_certificate_arn : null
    ssl_support_method             = local.use_custom ? "sni-only" : null
    minimum_protocol_version       = local.use_custom ? "TLSv1.2_2021" : null
  }

  logging_config {
    bucket          = "${var.logs_bucket_id}.s3.amazonaws.com"
    prefix          = "cloudfront-access-logs/"
    include_cookies = false
  }

  tags = { Name = "${var.project}-${var.environment}-cf" }
}

# ─── S3 bucket policy — grant CloudFront OAC access ──────────────────────────
# The policy lives here (not in the s3 module) because it needs the
# distribution ARN, which is only known after CloudFront is created.

data "aws_iam_policy_document" "cf_oac_access" {
  statement {
    sid       = "AllowCloudFrontOAC"
    actions   = ["s3:GetObject"]
    resources = ["${var.website_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = var.website_bucket_id
  policy = data.aws_iam_policy_document.cf_oac_access.json
}
