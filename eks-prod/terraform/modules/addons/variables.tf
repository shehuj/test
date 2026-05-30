variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "ebs_csi_role_arn" {
  description = "IRSA role ARN for the EBS CSI driver service account"
  type        = string
}
