# ─── Cluster security group (control-plane ENIs) ─────────────────────────────

resource "aws_security_group" "cluster" {
  #checkov:skip=CKV2_AWS_5:Attached to the EKS cluster in module.eks — cross-module reference not visible to static analysis
  name        = "${var.cluster_name}-cluster-sg"
  description = "EKS cluster control-plane security group"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.cluster_name}-cluster-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "cluster_egress_all" {
  #checkov:skip=CKV_AWS_382:Intentional — control plane must reach AWS service endpoints; all egress exits via NAT Gateways; nodes have no public IPs
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cluster.id
  description       = "Allow all outbound from control plane"
}

resource "aws_security_group_rule" "cluster_ingress_nodes_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node.id
  security_group_id        = aws_security_group.cluster.id
  description              = "Nodes to API server HTTPS"
}

# ─── Node security group ──────────────────────────────────────────────────────

resource "aws_security_group" "node" {
  #checkov:skip=CKV2_AWS_5:Attached to launch templates in module.node_groups — cross-module reference not visible to static analysis
  name        = "${var.cluster_name}-node-sg"
  description = "EKS worker node security group"
  vpc_id      = var.vpc_id

  tags = {
    Name                                        = "${var.cluster_name}-node-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "node_egress_all" {
  #checkov:skip=CKV_AWS_382:Intentional — nodes pull images and call AWS APIs; all egress exits via per-AZ NAT Gateways; no public node IPs
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.node.id
  description       = "Allow all outbound from nodes"
}

resource "aws_security_group_rule" "node_ingress_self" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.node.id
  security_group_id        = aws_security_group.node.id
  description              = "Node-to-node all traffic"
}

resource "aws_security_group_rule" "node_ingress_cluster" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.node.id
  description              = "Control plane to node ephemeral ports"
}

resource "aws_security_group_rule" "node_ingress_cluster_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.node.id
  description              = "Control plane to node HTTPS (webhooks)"
}

# SSH is disabled by default — resource not created unless allowed_ssh_cidrs is non-empty.
resource "aws_security_group_rule" "node_ssh" {
  #checkov:skip=CKV_AWS_24:SSH is opt-in only; this resource has count=0 (does not exist) when allowed_ssh_cidrs is empty, which is the default
  count = length(var.allowed_ssh_cidrs) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidrs
  security_group_id = aws_security_group.node.id
  description       = "SSH from allowed CIDRs"
}
