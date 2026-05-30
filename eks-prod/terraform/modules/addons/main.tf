resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = var.cluster_name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    enableNetworkPolicy = "true"
  })

  tags = { Name = "${var.cluster_name}-vpc-cni" }
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = var.cluster_name
  addon_name                  = "coredns"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = { Name = "${var.cluster_name}-coredns" }
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = var.cluster_name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = { Name = "${var.cluster_name}-kube-proxy" }
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = var.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = var.ebs_csi_role_arn
  resolve_conflicts_on_update = "OVERWRITE"

  tags = { Name = "${var.cluster_name}-ebs-csi" }
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = var.cluster_name
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = { Name = "${var.cluster_name}-pod-identity-agent" }
}
