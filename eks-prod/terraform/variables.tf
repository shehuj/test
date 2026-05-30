variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (e.g. prod, staging)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "environment must be one of: prod, staging, dev"
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-prod"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "owner" {
  description = "Team or individual responsible for this cluster"
  type        = string
  default     = "platform-team"
}

# ─── VPC ─────────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets (one per AZ — must have at least 2)"
  type        = list(string)
  default     = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (used by load balancers only)"
  type        = list(string)
  default     = ["10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20"]
}

# ─── EKS endpoint access ─────────────────────────────────────────────────────

variable "endpoint_private_access" {
  description = "Enable private API server endpoint (required for private-only)"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint (if enabled)"
  type        = list(string)
  default     = [] # Restrict to your corporate egress IPs
}

# ─── Node groups ─────────────────────────────────────────────────────────────

variable "system_node_instance_types" {
  description = "EC2 instance types for the system node group"
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
  description = "EC2 instance types for the application node group"
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
  description = "Root EBS volume size in GB for all nodes"
  type        = number
  default     = 50
}

# ─── Logging ─────────────────────────────────────────────────────────────────

variable "cluster_log_retention_days" {
  description = "CloudWatch log retention for cluster control-plane logs (minimum 365 for CKV_AWS_338)"
  type        = number
  default     = 365

  validation {
    condition     = var.cluster_log_retention_days >= 365
    error_message = "cluster_log_retention_days must be at least 365 days to meet compliance requirements."
  }
}

variable "flow_log_retention_days" {
  description = "CloudWatch log retention for VPC flow logs (minimum 365 for CKV_AWS_338)"
  type        = number
  default     = 365

  validation {
    condition     = var.flow_log_retention_days >= 365
    error_message = "flow_log_retention_days must be at least 365 days to meet compliance requirements."
  }
}

# ─── Allowed CIDRs for node-group SSH (leave empty to disable) ───────────────

variable "allowed_ssh_cidrs" {
  description = "CIDRs permitted to SSH to nodes — leave empty to block all SSH"
  type        = list(string)
  default     = []
}
