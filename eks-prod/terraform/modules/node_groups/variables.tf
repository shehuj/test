variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for worker nodes"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where nodes are launched"
  type        = list(string)
}

variable "node_sg_id" {
  description = "Security group ID to attach to worker nodes"
  type        = string
}

variable "ebs_kms_key_arn" {
  description = "KMS key ARN used to encrypt node EBS volumes"
  type        = string
}

variable "system_node_instance_types" {
  description = "Instance types for the system node group"
  type        = list(string)
  default     = ["m5.large"]
}

variable "system_node_min" {
  type    = number
  default = 2
}

variable "system_node_max" {
  type    = number
  default = 6
}

variable "system_node_desired" {
  type    = number
  default = 2
}

variable "app_node_instance_types" {
  description = "Instance types for the application node group"
  type        = list(string)
  default     = ["m5.2xlarge"]
}

variable "app_node_min" {
  type    = number
  default = 2
}

variable "app_node_max" {
  type    = number
  default = 20
}

variable "app_node_desired" {
  type    = number
  default = 3
}

variable "node_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 50
}
