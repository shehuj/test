provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.cluster_name
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

# ─── KMS keys (no upstream dependencies) ─────────────────────────────────────

module "kms" {
  source = "./modules/kms"

  cluster_name = var.cluster_name
  aws_region   = var.aws_region
}

# ─── VPC (depends on KMS for flow-log encryption) ────────────────────────────

module "vpc" {
  source = "./modules/vpc"

  cluster_name            = var.cluster_name
  vpc_cidr                = var.vpc_cidr
  private_subnet_cidrs    = var.private_subnet_cidrs
  public_subnet_cidrs     = var.public_subnet_cidrs
  flow_log_retention_days = var.flow_log_retention_days
  cloudwatch_kms_key_arn  = module.kms.cloudwatch_key_arn
}

# ─── Security groups (depends on VPC) ────────────────────────────────────────

module "security_groups" {
  source = "./modules/security_groups"

  cluster_name      = var.cluster_name
  vpc_id            = module.vpc.vpc_id
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}

# ─── IAM roles (no upstream dependencies) ────────────────────────────────────

module "iam" {
  source = "./modules/iam"

  cluster_name = var.cluster_name
}

# ─── EKS cluster (depends on IAM, security groups, VPC, KMS) ─────────────────
# depends_on ensures all policy attachments in module.iam are complete before
# the cluster is created — referencing only the role ARN would not guarantee this.

module "eks" {
  source = "./modules/eks"

  cluster_name               = var.cluster_name
  cluster_version            = var.cluster_version
  cluster_role_arn           = module.iam.cluster_role_arn
  cluster_sg_id              = module.security_groups.cluster_sg_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  endpoint_private_access    = var.endpoint_private_access
  endpoint_public_access     = var.endpoint_public_access
  public_access_cidrs        = var.public_access_cidrs
  eks_secrets_kms_key_arn    = module.kms.eks_secrets_key_arn
  cloudwatch_kms_key_arn     = module.kms.cloudwatch_key_arn
  cluster_log_retention_days = var.cluster_log_retention_days

  depends_on = [module.iam]
}

# ─── IRSA roles (depends on EKS OIDC provider) ───────────────────────────────

module "irsa" {
  source = "./modules/irsa"

  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  ebs_kms_key_arn   = module.kms.ebs_key_arn
}

# ─── Node groups (depends on IAM, security groups, VPC, KMS, EKS) ────────────
# depends_on ensures node policy attachments are complete before nodes join.

module "node_groups" {
  source = "./modules/node_groups"

  cluster_name       = module.eks.cluster_name
  node_role_arn      = module.iam.node_role_arn
  private_subnet_ids = module.vpc.private_subnet_ids
  node_sg_id         = module.security_groups.node_sg_id
  ebs_kms_key_arn    = module.kms.ebs_key_arn

  system_node_instance_types = var.system_node_instance_types
  system_node_min            = var.system_node_min
  system_node_max            = var.system_node_max
  system_node_desired        = var.system_node_desired

  app_node_instance_types = var.app_node_instance_types
  app_node_min            = var.app_node_min
  app_node_max            = var.app_node_max
  app_node_desired        = var.app_node_desired

  node_volume_size = var.node_volume_size

  depends_on = [module.iam]
}

# ─── EKS addons (depends on node groups being ready) ─────────────────────────

module "addons" {
  source = "./modules/addons"

  cluster_name     = module.eks.cluster_name
  ebs_csi_role_arn = module.irsa.ebs_csi_role_arn

  depends_on = [module.node_groups, module.irsa]
}
