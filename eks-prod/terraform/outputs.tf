output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority" {
  description = "Base64-encoded cluster CA certificate"
  value       = module.eks.cluster_certificate_authority
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "Full OIDC issuer URL for IRSA"
  value       = module.eks.oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "ARN of the EKS OIDC identity provider"
  value       = module.eks.oidc_provider_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (nodes)"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs (load balancers)"
  value       = module.vpc.public_subnet_ids
}

output "node_security_group_id" {
  description = "Node group security group ID"
  value       = module.security_groups.node_sg_id
}

output "cluster_autoscaler_role_arn" {
  description = "IRSA role ARN for the Cluster Autoscaler"
  value       = module.irsa.cluster_autoscaler_role_arn
}

output "alb_controller_role_arn" {
  description = "IRSA role ARN for the AWS Load Balancer Controller"
  value       = module.irsa.alb_controller_role_arn
}

output "ebs_csi_role_arn" {
  description = "IRSA role ARN for the EBS CSI driver"
  value       = module.irsa.ebs_csi_role_arn
}

output "ebs_kms_key_arn" {
  description = "ARN of the EBS encryption KMS key"
  value       = module.kms.ebs_key_arn
}

output "kubeconfig_command" {
  description = "AWS CLI command to update local kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
