variable "cluster_name" {
  description = "EKS cluster name — used to name keys and aliases"
  type        = string
}

variable "aws_region" {
  description = "AWS region — used to scope the CloudWatch KMS key policy"
  type        = string
}
