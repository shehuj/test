output "cluster_sg_id" {
  description = "Security group ID for the EKS control-plane ENIs"
  value       = aws_security_group.cluster.id
}

output "node_sg_id" {
  description = "Security group ID for worker nodes"
  value       = aws_security_group.node.id
}
