variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane"
  type        = string
}

variable "cluster_sg_id" {
  description = "Security group ID for the EKS control-plane ENIs"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs in which the control plane ENIs are placed"
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public endpoint (if enabled)"
  type        = list(string)
  default     = []
}

variable "eks_secrets_kms_key_arn" {
  description = "KMS key ARN used to encrypt Kubernetes secrets in etcd"
  type        = string
}

variable "cloudwatch_kms_key_arn" {
  description = "KMS key ARN used to encrypt the control-plane CloudWatch log group"
  type        = string
}

variable "cluster_log_retention_days" {
  description = "CloudWatch log retention for control-plane logs"
  type        = number
  default     = 90
}
