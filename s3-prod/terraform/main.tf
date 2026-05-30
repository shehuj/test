provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

# ─── S3 buckets (website + access logs) ──────────────────────────────────────

module "s3" {
  source = "./modules/s3"

  project             = var.project
  environment         = var.environment
  index_document      = var.index_document
  error_document      = var.error_document
  logs_retention_days = var.logs_retention_days
}

# ─── CloudFront distribution + OAC + bucket policy ───────────────────────────

module "cloudfront" {
  source = "./modules/cloudfront"

  project                        = var.project
  environment                    = var.environment
  website_bucket_arn             = module.s3.bucket_arn
  website_bucket_id              = module.s3.bucket_id
  website_bucket_regional_domain = module.s3.bucket_regional_domain
  logs_bucket_id                 = module.s3.logs_bucket_id
  index_document                 = var.index_document
  error_document                 = var.error_document
  price_class                    = var.price_class
  custom_domain                  = var.custom_domain
  acm_certificate_arn            = var.acm_certificate_arn
  geo_restriction_locations      = var.geo_restriction_locations
}
