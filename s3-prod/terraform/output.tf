output "website_bucket_name" {
  description = "S3 website bucket name"
  value       = module.s3.bucket_id
}

output "website_bucket_arn" {
  description = "S3 website bucket ARN"
  value       = module.s3.bucket_arn
}

output "logs_bucket_name" {
  description = "S3 access logs bucket name"
  value       = module.s3.logs_bucket_id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (used with aws cloudfront create-invalidation)"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain — use this as your website URL"
  value       = "https://${module.cloudfront.distribution_domain_name}"
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID — use for Route53 alias records pointing to this distribution"
  value       = module.cloudfront.distribution_hosted_zone_id
}

output "deploy_command" {
  description = "AWS CLI command to sync local build output to the website bucket"
  value       = "aws s3 sync ./dist s3://${module.s3.bucket_id} --delete"
}

output "invalidate_command" {
  description = "AWS CLI command to invalidate the CloudFront cache after a deploy"
  value       = "aws cloudfront create-invalidation --distribution-id ${module.cloudfront.distribution_id} --paths '/*'"
}
