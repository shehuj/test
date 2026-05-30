variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "website_bucket_arn" {
  description = "ARN of the S3 website bucket"
  type        = string
}

variable "website_bucket_id" {
  description = "ID (name) of the S3 website bucket"
  type        = string
}

variable "website_bucket_regional_domain" {
  description = "Regional domain name of the S3 website bucket"
  type        = string
}

variable "logs_bucket_id" {
  description = "ID (name) of the S3 access logs bucket"
  type        = string
}

variable "index_document" {
  description = "Default root object served from CloudFront"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Path returned to the viewer on 4xx errors"
  type        = string
  default     = "error.html"
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "custom_domain" {
  description = "Optional custom domain alias (e.g. www.example.com)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (us-east-1) for the custom domain"
  type        = string
  default     = ""
}

variable "geo_restriction_locations" {
  description = "Country codes to block (ISO 3166-1-alpha-2). Empty = allow all."
  type        = list(string)
  default     = []
}
