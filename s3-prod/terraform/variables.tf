variable "aws_region" {
  description = "AWS region for all resources except ACM (CloudFront requires us-east-1 for certs)"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "environment must be one of: prod, staging, dev."
  }
}

variable "project" {
  description = "Project name — used to name all resources"
  type        = string
  default     = "my-website"
}

variable "owner" {
  description = "Team or individual responsible for this infrastructure"
  type        = string
  default     = "platform-team"
}

# ─── S3 ───────────────────────────────────────────────────────────────────────

variable "website_prefix" {
  description = "S3 key prefix for this project's files (e.g. 'project-a'). CloudFront origin_path is set to /prefix so each prefix acts as an independent site root. Leave empty for root-level deployment."
  type        = string
  default     = ""
}

variable "index_document" {
  description = "Default root object served by the website (e.g. index.html)"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Object returned on 4xx errors (e.g. error.html or index.html for SPAs)"
  type        = string
  default     = "error.html"
}

variable "logs_retention_days" {
  description = "Retention period in days for S3 access logs"
  type        = number
  default     = 90
}

# ─── CloudFront ───────────────────────────────────────────────────────────────

variable "price_class" {
  description = "CloudFront price class (ALL = global, 100 = NA+EU only, 200 = NA+EU+Asia)"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "price_class must be PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "custom_domain" {
  description = "Optional custom domain (e.g. www.example.com). Leave empty to use the CloudFront default domain."
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for the custom domain (must be in us-east-1). Required when custom_domain is set."
  type        = string
  default     = ""
}

variable "geo_restriction_locations" {
  description = "ISO 3166-1-alpha-2 country codes to BLOCK. Leave empty to allow all countries."
  type        = list(string)
  default     = []
}
