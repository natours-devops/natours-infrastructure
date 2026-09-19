data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#Shared trust policy for all pod roles
locals {
  pod_identity_trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}


//ROLE 1 — EKS Cluster Role
resource "aws_iam_role" "cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${var.cluster_name}-cluster-role" }
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}


# ROLE 2 — EKS Node Role
resource "aws_iam_role" "node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${var.cluster_name}-node-role" }
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node_role.name
}

# ════════════════════════════════════════
# ROLE 3 — ALB Controller Role
# Method: EKS Pod Identity
# Attaches to: kube-system/aws-load-balancer-controller
# ════════════════════════════════════════
resource "aws_iam_role" "alb_controller" {
  name               = "${var.cluster_name}-alb-controller-role"
  assume_role_policy = local.pod_identity_trust_policy
  tags               = { Name = "${var.cluster_name}-alb-controller-role" }
}

resource "aws_iam_policy" "alb_controller" {
  name        = "${var.cluster_name}-alb-controller-policy"
  description = "Allows ALB controller to manage load balancers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["iam:CreateServiceLinkedRole"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  policy_arn = aws_iam_policy.alb_controller.arn
  role       = aws_iam_role.alb_controller.name
}

resource "aws_eks_pod_identity_association" "alb_controller" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.alb_controller.arn

  depends_on = [var.cluster_depends_on]
}

# ════════════════════════════════════════
# ROLE 4 — Booking Service Role
# Method: EKS Pod Identity
# Attaches to: default/booking-service-sa
# Permission: SQS publish only
# ══════════════════════════════════════
resource "aws_iam_policy" "booking_sqs" {
  name        = "${var.cluster_name}-booking-sqs-policy"
  description = "Allows booking service to publish to SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:SendMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl"
      ]
      Resource = var.sqs_queue_arn
    }]
  })
}

resource "aws_iam_role" "booking_service" {
  name               = "${var.cluster_name}-booking-service-role"
  assume_role_policy = local.pod_identity_trust_policy
  tags               = { Name = "${var.cluster_name}-booking-service-role" }
}

resource "aws_iam_role_policy_attachment" "booking_sqs" {
  policy_arn = aws_iam_policy.booking_sqs.arn
  role       = aws_iam_role.booking_service.name
}

resource "aws_iam_role_policy_attachment" "booking_secrets" {
  policy_arn = aws_iam_policy.secrets_manager.arn  
  role       = aws_iam_role.booking_service.name   
}

resource "aws_eks_pod_identity_association" "booking_service" {
  cluster_name    = var.cluster_name
  namespace       = "default"
  service_account = "booking-service-sa"
  role_arn        = aws_iam_role.booking_service.arn

  depends_on = [var.cluster_depends_on]
}

# ════════════════════════════════════════
# ROLE 5 — Notification Service Role
# Method: EKS Pod Identity
# Attaches to: default/notification-service-sa
# Permission: SQS consume + delete
# ════════════════════════════════════════
resource "aws_iam_policy" "notification_sqs" {
  name        = "${var.cluster_name}-notification-sqs-policy"
  description = "Allows notification service to consume from SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ChangeMessageVisibility"
      ]
      Resource = [
        var.sqs_queue_arn,
        var.sqs_dlq_arn
      ]
    }]
  })
}

resource "aws_iam_role" "notification_service" {
  name               = "${var.cluster_name}-notification-service-role"
  assume_role_policy = local.pod_identity_trust_policy
  tags               = { Name = "${var.cluster_name}-notification-service-role" }
}

resource "aws_iam_role_policy_attachment" "notification_sqs" {
  policy_arn = aws_iam_policy.notification_sqs.arn
  role       = aws_iam_role.notification_service.name
}

resource "aws_iam_role_policy_attachment" "notification_secrets" {
  policy_arn = aws_iam_policy.secrets_manager.arn
  role       = aws_iam_role.notification_service.name 
}

resource "aws_eks_pod_identity_association" "notification_service" {
  cluster_name    = var.cluster_name
  namespace       = "default"
  service_account = "notification-service-sa"
  role_arn        = aws_iam_role.notification_service.arn

  depends_on = [var.cluster_depends_on]
}

# ════════════════════════════════════════
# ROLE 6 — All Services Role
# Method: EKS Pod Identity
# Attaches to: default/all-services-sa
# Permission: Secrets Manager read
# ════════════════════════════════════════
resource "aws_iam_policy" "secrets_manager" {
  name        = "${var.cluster_name}-secrets-manager-policy"
  description = "Allows all services to read secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:natours/*"
    }]
  })
}

resource "aws_iam_role" "all_services" {
  name               = "${var.cluster_name}-all-services-role"
  assume_role_policy = local.pod_identity_trust_policy
  tags               = { Name = "${var.cluster_name}-all-services-role" }
}

resource "aws_iam_role_policy_attachment" "all_services_secrets" {
  policy_arn = aws_iam_policy.secrets_manager.arn
  role       = aws_iam_role.all_services.name
}

resource "aws_eks_pod_identity_association" "all_services" {
  cluster_name    = var.cluster_name
  namespace       = "default"
  service_account = "all-services-sa"
  role_arn        = aws_iam_role.all_services.arn

  depends_on = [var.cluster_depends_on]
}