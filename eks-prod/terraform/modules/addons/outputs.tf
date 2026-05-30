output "vpc_cni_version" {
  description = "Installed VPC CNI addon version"
  value       = aws_eks_addon.vpc_cni.addon_version
}

output "coredns_version" {
  description = "Installed CoreDNS addon version"
  value       = aws_eks_addon.coredns.addon_version
}

output "ebs_csi_version" {
  description = "Installed EBS CSI driver addon version"
  value       = aws_eks_addon.ebs_csi.addon_version
}
