# ─── System node group ────────────────────────────────────────────────────────

resource "aws_launch_template" "system" {
  name_prefix            = "${var.cluster_name}-system-"
  description            = "Launch template for EKS system node group"
  update_default_version = true

  # IMDSv2 required — prevents SSRF-based credential theft
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  ebs_optimized = true

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.node_volume_size
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.ebs_kms_key_arn
      delete_on_termination = true
    }
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.node_sg_id]
    delete_on_termination       = true
  }

  monitoring { enabled = true }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name                                        = "${var.cluster_name}-system-node"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      NodeGroup                                   = "system"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags          = { Name = "${var.cluster_name}-system-node-volume", Encrypted = "true" }
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_eks_node_group" "system" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-system"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = "ON_DEMAND"
  instance_types = var.system_node_instance_types

  launch_template {
    id      = aws_launch_template.system.id
    version = aws_launch_template.system.latest_version
  }

  scaling_config {
    min_size     = var.system_node_min
    max_size     = var.system_node_max
    desired_size = var.system_node_desired
  }

  update_config { max_unavailable_percentage = 33 }

  # Prevent general workloads from landing on system nodes
  taint {
    key    = "CriticalAddonsOnly"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  labels = {
    role      = "system"
    nodegroup = "${var.cluster_name}-system"
  }

  tags = {
    Name                                                 = "${var.cluster_name}-system"
    "k8s.io/cluster-autoscaler/${var.cluster_name}"      = "owned"
    "k8s.io/cluster-autoscaler/enabled"                  = "true"
    "k8s.io/cluster-autoscaler/node-template/label/role" = "system"
  }

  lifecycle { ignore_changes = [scaling_config[0].desired_size] }
}

# ─── Application node group ───────────────────────────────────────────────────

resource "aws_launch_template" "app" {
  name_prefix            = "${var.cluster_name}-app-"
  description            = "Launch template for EKS application node group"
  update_default_version = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  ebs_optimized = true

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.node_volume_size
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.ebs_kms_key_arn
      delete_on_termination = true
    }
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.node_sg_id]
    delete_on_termination       = true
  }

  monitoring { enabled = true }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name                                        = "${var.cluster_name}-app-node"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      NodeGroup                                   = "app"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags          = { Name = "${var.cluster_name}-app-node-volume", Encrypted = "true" }
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_eks_node_group" "app" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-app"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = "ON_DEMAND"
  instance_types = var.app_node_instance_types

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  scaling_config {
    min_size     = var.app_node_min
    max_size     = var.app_node_max
    desired_size = var.app_node_desired
  }

  update_config { max_unavailable_percentage = 25 }

  labels = {
    role      = "app"
    nodegroup = "${var.cluster_name}-app"
  }

  tags = {
    Name                                                 = "${var.cluster_name}-app"
    "k8s.io/cluster-autoscaler/${var.cluster_name}"      = "owned"
    "k8s.io/cluster-autoscaler/enabled"                  = "true"
    "k8s.io/cluster-autoscaler/node-template/label/role" = "app"
  }

  lifecycle { ignore_changes = [scaling_config[0].desired_size] }
}
