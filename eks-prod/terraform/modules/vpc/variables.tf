variable "cluster_name" {
  description = "EKS cluster name — used for resource naming and subnet tags"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets (one per AZ)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (load balancers only)"
  type        = list(string)
}

variable "flow_log_retention_days" {
  description = "CloudWatch log retention in days for VPC flow logs"
  type        = number
}

variable "cloudwatch_kms_key_arn" {
  description = "KMS key ARN used to encrypt the flow-log CloudWatch log group"
  type        = string
}
