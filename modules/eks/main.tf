#EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = "1.34"
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids              = var.private_subnets
    endpoint_public_access  = true
    endpoint_private_access = true
  }
  
  #these kind of vlogs send to cloudWatch
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = {
    Name = var.cluster_name
  }
}

#Node Group
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnets
  disk_size = 20
  instance_types  = ["t3.small"]
  capacity_type   = "ON_DEMAND"

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name = "${var.cluster_name}-node-group"
  }

  depends_on = [aws_eks_cluster.this]
}

#Pod Identity Agent Addon 
resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "eks-pod-identity-agent"

  depends_on = [aws_eks_node_group.this]
}