# eks-prod

Production-grade EKS cluster — Terraform + GitHub Actions CI/CD with security gates.

## Architecture

```
AWS Account
└── VPC (10.0.0.0/16)
    ├── Private Subnets ×3 AZs  ← nodes, no public IPs
    │   └── EKS Node Groups
    │       ├── system   (m5.large  ×2–6)   # kube-system only
    │       └── app      (m5.2xlarge ×2–20) # workloads
    ├── Public Subnets  ×3 AZs  ← ALB only
    └── NAT Gateways    ×3 AZs  ← HA outbound

EKS Control Plane (private endpoint)
├── Secrets encrypted at rest (KMS)
├── All control-plane logs → CloudWatch (KMS-encrypted, 90d)
├── OIDC provider → IRSA (per-pod AWS permissions)
└── Managed Addons: VPC CNI, CoreDNS, kube-proxy, EBS CSI, Pod Identity
```

## Security controls

| Control | Implementation |
|---------|---------------|
| Private API endpoint | `endpoint_public_access = false` |
| Secrets encryption | KMS CMK on etcd |
| Node IMDSv2 only | `http_tokens = required` in launch template |
| No public node IPs | `map_public_ip_on_launch = false` |
| EBS encryption | KMS CMK on all node volumes |
| Control-plane audit logs | All 5 log types → CloudWatch |
| VPC Flow Logs | ALL traffic → CloudWatch (KMS-encrypted) |
| Least-privilege IAM | Separate cluster/node/addon roles; IRSA for pods |
| Network policy | Enabled via VPC CNI |
| Key rotation | All KMS keys auto-rotate annually |

## CI/CD pipeline

```
PR / push → eks-prod/**
  ├── tfsec    (IaC SAST, SARIF → GitHub Security)
  ├── checkov  (policy-as-code)
  ├── trivy    (vulnerability + config scan)
  └── tflint   (Terraform linting)
        ↓ all pass
  └── terraform fmt / validate / plan
        ↓ merge to main
  └── [manual approval — production environment]
        ↓ approved
  └── terraform apply
```

## Prerequisites

1. **S3 state bucket + DynamoDB lock table** — bootstrap once:
   ```bash
   aws s3api create-bucket --bucket <your-bucket> --region us-east-1
   aws s3api put-bucket-versioning --bucket <your-bucket> --versioning-configuration Status=Enabled
   aws s3api put-bucket-encryption --bucket <your-bucket> \
     --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms"}}]}'
   aws dynamodb create-table --table-name terraform-state-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

2. **GitHub Secrets** (repo Settings → Secrets):
   | Secret | Value |
   |--------|-------|
   | `AWS_DEPLOY_ROLE_ARN` | ARN of the IAM role GitHub OIDC can assume |
   | `TF_STATE_BUCKET` | S3 bucket name for Terraform state |
   | `TF_LOCK_TABLE` | DynamoDB table name for state locking |
   | `EKS_CLUSTER_NAME` | Cluster name (e.g. `eks-prod`) |

3. **GitHub Environment** — create a `production` environment with required reviewers under repo Settings → Environments.

4. **AWS IAM OIDC trust** for GitHub Actions:
   ```bash
   # One-time setup — creates the OIDC provider for GitHub
   aws iam create-open-id-connect-provider \
     --url https://token.actions.githubusercontent.com \
     --client-id-list sts.amazonaws.com \
     --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
   ```

## Local usage

```bash
cd eks-prod/terraform

# Copy and edit vars
cp terraform.tfvars.example terraform.tfvars

# Run security scans locally before committing
tfsec . --config-file ../.tfsec.yml --minimum-severity MEDIUM
trivy config . --severity MEDIUM,HIGH,CRITICAL
checkov -d . --framework terraform

# Terraform workflow
terraform init
terraform validate
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan

# Connect to cluster (requires VPN or bastion for private endpoint)
aws eks update-kubeconfig --region us-east-1 --name eks-prod
```

## Post-deploy steps

After `terraform apply`, install the Cluster Autoscaler and AWS Load Balancer Controller
using the IRSA role ARNs from Terraform outputs:

```bash
terraform output cluster_autoscaler_role_arn
terraform output alb_controller_role_arn
```

Then deploy via Helm:
```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=eks-prod \
  --set rbac.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<IRSA_ARN>
```
