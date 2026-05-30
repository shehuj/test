# eks-prod

Production-grade EKS cluster — modular Terraform + GitHub Actions CI/CD with security gates.

## Architecture

```
AWS Account
└── VPC (10.0.0.0/16)
    ├── Private Subnets ×3 AZs  ← nodes, no public IPs
    │   └── EKS Node Groups
    │       ├── system   (m5.large  ×2–6)    kube-system only, CriticalAddonsOnly taint
    │       └── app      (m5.2xlarge ×2–20)  workloads, cluster-autoscaler managed
    ├── Public Subnets  ×3 AZs  ← ALB/NLB only
    ├── NAT Gateways    ×3 AZs  ← HA outbound (one per AZ)
    └── Default SG      locked  ← no rules (CKV2_AWS_12)

EKS Control Plane (private endpoint only)
├── Secrets encrypted at rest (KMS CMK)
├── All 5 control-plane log types → CloudWatch (KMS-encrypted, 365d retention)
├── VPC Flow Logs → CloudWatch (KMS-encrypted, 365d retention)
├── OIDC provider → IRSA (per-pod AWS permissions, no node-level credentials)
└── Managed Addons: VPC CNI (network policy on), CoreDNS, kube-proxy, EBS CSI, Pod Identity
```

## Module structure

```
terraform/
├── main.tf                  root — wires all modules together
├── variables.tf             all input variables
├── outputs.tf               re-exports module outputs
├── versions.tf              provider pins + S3 backend
└── modules/
    ├── kms/                 3 KMS CMKs: eks-secrets, ebs, cloudwatch
    ├── vpc/                 VPC, subnets, NAT GWs, flow logs, default SG lockdown
    ├── security_groups/     cluster + node SGs and all ingress/egress rules
    ├── iam/                 cluster role + node role + policy attachments
    ├── eks/                 EKS cluster, OIDC provider, CloudWatch log group
    ├── irsa/                IRSA roles: cluster-autoscaler, ALB controller, EBS CSI
    ├── node_groups/         system + app launch templates + managed node groups
    └── addons/              vpc-cni, coredns, kube-proxy, aws-ebs-csi-driver, pod-identity-agent
```

**Dependency order:** `kms` → `vpc` → `security_groups` → `iam` → `eks` → `irsa` → `node_groups` → `addons`

## Security controls

| Control | Implementation |
|---------|----------------|
| Private API endpoint only | `endpoint_public_access = false` |
| Secrets encryption at rest | KMS CMK on etcd |
| Node IMDSv2 required | `http_tokens = required` in every launch template |
| No public node IPs | `map_public_ip_on_launch = false`, nodes in private subnets |
| EBS volumes encrypted | KMS CMK on all node EBS volumes |
| Control-plane audit logs | All 5 log types → CloudWatch (365-day retention) |
| VPC Flow Logs | ALL traffic → CloudWatch (KMS-encrypted, 365-day retention) |
| Default SG locked | `aws_default_security_group` with no rules |
| Least-privilege IAM | Separate roles per layer; IRSA for pod-level AWS access |
| Network policy | Enabled in VPC CNI addon |
| KMS key rotation | Annual auto-rotation on all 3 CMKs |
| SSH disabled by default | `allowed_ssh_cidrs = []`; node_ssh rule has `count = 0` |

## CI/CD pipeline

```
PR / push to eks-prod/**
  ├── tfsec    IaC static analysis   → SARIF to GitHub Security tab
  ├── checkov  policy-as-code        → SARIF to GitHub Security tab
  ├── trivy    IaC vulnerability scan → SARIF to GitHub Security tab
  └── tflint   Terraform linting
        ↓ all 4 must pass
  └── terraform fmt / validate / plan
        ↓ merge to main (or workflow_dispatch apply)
  └── manual approval  (production GitHub Environment)
        ↓ approved
  └── terraform apply
```

Destroy is also gated behind the `production` environment approval and can only
be triggered via `workflow_dispatch`.

## Prerequisites

### 1. S3 state bucket + DynamoDB lock table

Bootstrap once with your AWS credentials:

```bash
aws s3api create-bucket --bucket <your-bucket> --region us-east-1
aws s3api put-bucket-versioning \
  --bucket <your-bucket> --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket <your-bucket> \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms"}}]}'
aws dynamodb create-table --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Update `versions.tf` → replace `REPLACE_WITH_YOUR_STATE_BUCKET` with the bucket name.

### 2. GitHub OIDC → AWS trust (one-time per AWS account)

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 3. IAM deploy role

Create an IAM role with this trust policy, then attach the permissions Terraform needs:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:<GITHUB_ORG_OR_USER>/*:environment:production"
      }
    }
  }]
}
```

> The `sub` condition is scoped to the `production` GitHub Environment so only
> manually-approved apply/destroy jobs can assume this role.
> Change `environment:production` to `*` to allow all jobs, or to a specific
> `ref:refs/heads/main` to restrict to the main branch.

### 4. GitHub Secrets

Add these under repo **Settings → Secrets → Actions**:

| Secret | Value |
|--------|-------|
| `AWS_REGION` | e.g. `us-east-1` |
| `AWS_DEPLOY_ROLE_ARN` | ARN of the IAM role created above |
| `TF_STATE_BUCKET` | S3 bucket name for Terraform state |
| `TF_LOCK_TABLE` | DynamoDB table name (e.g. `terraform-state-lock`) |
| `EKS_CLUSTER_NAME` | Cluster name (e.g. `eks-prod`) |

### 5. GitHub Environment

Create a `production` environment with required reviewers under repo
**Settings → Environments → New environment**. The apply and destroy jobs will
pause for approval before running.

## Local usage

```bash
cd eks-prod/terraform

# Copy and fill in your values
cp terraform.tfvars.example terraform.tfvars

# Security scans (must all pass before committing)
tfsec . --config-file ../.tfsec.yml --minimum-severity MEDIUM
trivy config . --severity MEDIUM,HIGH,CRITICAL --ignorefile .trivyignore
checkov -d . --framework terraform --compact --quiet

# Terraform workflow
terraform init
terraform validate
terraform fmt -check -recursive
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan

# Connect to the cluster (requires VPN or bastion — private endpoint)
aws eks update-kubeconfig --region us-east-1 --name eks-prod
```

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | API server endpoint |
| `oidc_provider_arn` | OIDC provider ARN (for additional IRSA roles) |
| `private_subnet_ids` | Private subnet IDs |
| `cluster_autoscaler_role_arn` | IRSA role for Cluster Autoscaler |
| `alb_controller_role_arn` | IRSA role for AWS Load Balancer Controller |
| `ebs_csi_role_arn` | IRSA role for EBS CSI driver |
| `ebs_kms_key_arn` | KMS key ARN for encrypted PVCs |
| `kubeconfig_command` | `aws eks update-kubeconfig ...` command |

## Post-deploy: install Cluster Autoscaler

```bash
terraform output -raw cluster_autoscaler_role_arn
# copy the ARN, then:

helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=eks-prod \
  --set rbac.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<IRSA_ARN>
```

## Post-deploy: install AWS Load Balancer Controller

```bash
terraform output -raw alb_controller_role_arn

helm repo add eks https://aws.github.io/eks-charts
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=eks-prod \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<IRSA_ARN>
```
