output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = aws_eks_cluster.main.version
}

output "cluster_certificate_authority" {
  description = "Base64-encoded cluster CA certificate"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "ARN of the EKS OIDC identity provider"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider without https:// prefix"
  value       = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}

output "oidc_issuer_url" {
  description = "Full OIDC issuer URL (with https://)"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}
