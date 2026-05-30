output "system_node_group_arn" {
  description = "ARN of the system managed node group"
  value       = aws_eks_node_group.system.arn
}

output "app_node_group_arn" {
  description = "ARN of the application managed node group"
  value       = aws_eks_node_group.app.arn
}
