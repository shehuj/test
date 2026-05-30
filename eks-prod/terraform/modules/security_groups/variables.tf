variable "cluster_name" {
  description = "EKS cluster name — used for resource naming and node SG tags"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID in which to create the security groups"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs allowed to SSH to worker nodes; empty list disables SSH"
  type        = list(string)
  default     = []
}
