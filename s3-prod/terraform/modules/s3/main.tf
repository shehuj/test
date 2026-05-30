locals {
  bucket_name      = "${var.project}-${var.environment}-website"
  logs_bucket_name = "${var.project}-${var.environment}-access-logs"
}

# ─── Access logs bucket ───────────────────────────────────────────────────────

resource "aws_s3_bucket" "logs" {
  #checkov:skip=CKV_AWS_144:Cross-region replication is not required for an access-logs bucket
  #checkov:skip=CKV_AWS_145:AES256 is appropriate for access logs; CMK adds no meaningful protection for non-sensitive log data
  #checkov:skip=CKV2_AWS_62:Event notifications are not required for an access-logs bucket
  bucket        = local.logs_bucket_name
  force_destroy = false

  tags = { Name = local.logs_bucket_name, Purpose = "access-logs" }
}

# BucketOwnerPreferred is required here — CloudFront and S3 server access logging
# use the log-delivery-write ACL which cannot work with BucketOwnerEnforced.
resource "aws_s3_bucket_ownership_controls" "logs" {
  #checkov:skip=CKV2_AWS_65:log-delivery-write ACL requires BucketOwnerPreferred; BucketOwnerEnforced would break log delivery
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  bucket = aws_s3_bucket.logs.id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.logs]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter { prefix = "" }

    expiration {
      days = var.logs_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Required by CKV_AWS_300 — prevents orphaned multipart uploads from accruing storage costs.
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ─── Website bucket ───────────────────────────────────────────────────────────

resource "aws_s3_bucket" "website" {
  #checkov:skip=CKV_AWS_144:Cross-region replication is optional for a static website; enable via var if required
  #checkov:skip=CKV_AWS_145:Website content is served publicly via CloudFront; CMK encryption adds complexity without security benefit for publicly accessible objects
  #checkov:skip=CKV2_AWS_62:Event notifications are not required for a static website bucket
  bucket        = local.bucket_name
  force_destroy = false

  tags = { Name = local.bucket_name, Purpose = "website-content" }
}

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

# tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block ALL public access — content is served exclusively through CloudFront OAC.
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_logging" "website" {
  bucket = aws_s3_bucket.website.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter { prefix = "" }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ─── CORS (required for fonts, API calls, etc.) ───────────────────────────────

resource "aws_s3_bucket_cors_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}
