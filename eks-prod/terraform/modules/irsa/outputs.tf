output "cluster_autoscaler_role_arn" {
  description = "IRSA role ARN for the Cluster Autoscaler"
  value       = aws_iam_role.cluster_autoscaler.arn
}

output "alb_controller_role_arn" {
  description = "IRSA role ARN for the AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller.arn
}

output "ebs_csi_role_arn" {
  description = "IRSA role ARN for the EBS CSI driver"
  value       = aws_iam_role.ebs_csi.arn
}
