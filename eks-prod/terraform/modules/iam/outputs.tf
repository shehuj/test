output "cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane"
  value       = aws_iam_role.cluster.arn
}

output "node_role_arn" {
  description = "IAM role ARN for worker nodes"
  value       = aws_iam_role.node.arn
}

# Expose attachment IDs so dependent modules can declare explicit depends_on
# without coupling to internal resource names.
output "cluster_policy_attachment_ids" {
  description = "IAM policy attachment IDs for the cluster role (used for depends_on)"
  value = [
    aws_iam_role_policy_attachment.cluster_eks_policy.id,
    aws_iam_role_policy_attachment.cluster_vpc_resource_controller.id,
  ]
}

output "node_policy_attachment_ids" {
  description = "IAM policy attachment IDs for the node role (used for depends_on)"
  value = [
    aws_iam_role_policy_attachment.node_worker_policy.id,
    aws_iam_role_policy_attachment.node_cni_policy.id,
    aws_iam_role_policy_attachment.node_ecr_read.id,
    aws_iam_role_policy_attachment.node_ssm.id,
  ]
}
