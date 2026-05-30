output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.website.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.website.arn
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name (e.g. d1234.cloudfront.net)"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "distribution_hosted_zone_id" {
  description = "CloudFront hosted zone ID (used for Route53 alias records)"
  value       = aws_cloudfront_distribution.website.hosted_zone_id
}

output "oac_id" {
  description = "Origin Access Control ID"
  value       = aws_cloudfront_origin_access_control.website.id
}
