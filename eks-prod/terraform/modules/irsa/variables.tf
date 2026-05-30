variable "cluster_name" {
  description = "EKS cluster name — used to name IRSA roles"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC identity provider"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the EKS OIDC identity provider (without https://)"
  type        = string
}

variable "ebs_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt EBS volumes (granted to EBS CSI)"
  type        = string
}
