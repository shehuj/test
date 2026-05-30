variable "project" {
  description = "Project name — used to name buckets"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "index_document" {
  description = "Default root object (e.g. index.html)"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error page object (e.g. error.html)"
  type        = string
  default     = "error.html"
}

variable "logs_retention_days" {
  description = "Retention in days for S3 access logs"
  type        = number
  default     = 90
}
