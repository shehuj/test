output "eks_secrets_key_arn" {
  description = "ARN of the KMS key used to encrypt EKS secrets"
  value       = aws_kms_key.eks_secrets.arn
}

output "ebs_key_arn" {
  description = "ARN of the KMS key used to encrypt EBS volumes"
  value       = aws_kms_key.ebs.arn
}

output "cloudwatch_key_arn" {
  description = "ARN of the KMS key used to encrypt CloudWatch log groups"
  value       = aws_kms_key.cloudwatch.arn
}
