output "bucket_id" {
  description = "Website S3 bucket name"
  value       = aws_s3_bucket.website.id
}

output "bucket_arn" {
  description = "Website S3 bucket ARN"
  value       = aws_s3_bucket.website.arn
}

output "bucket_regional_domain" {
  description = "Regional domain name of the website bucket (used as CloudFront origin)"
  value       = aws_s3_bucket.website.bucket_regional_domain_name
}

output "logs_bucket_id" {
  description = "Access logs S3 bucket name"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  description = "Access logs S3 bucket ARN"
  value       = aws_s3_bucket.logs.arn
}
