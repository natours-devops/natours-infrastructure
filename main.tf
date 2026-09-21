module "vpc" {
  source = "./modules/vpc"

  vpc_cidr = var.vpc_cidr
  vpc_name = "${var.project_name}_vpc"

  subnets = {
    "natours-public-us-east-1a" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "${var.aws_region}a"
      public            = true
    }

    "natours-public-us-east-1b" = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "${var.aws_region}b"
      public            = true
    }

    "natours-private-us-east-1a" = {
      cidr_block        = "10.0.3.0/24"
      availability_zone = "${var.aws_region}a"
      public            = false
    }

    "natours-private-us-east-1b" = {
      cidr_block        = "10.0.4.0/24"
      availability_zone = "${var.aws_region}b"
      public            = false
    }
  }
  
  rt_public_name  = "${var.project_name}_public_rt"
  rt_private_name = "${var.project_name}_private_rt"
  igw_name = "${var.project_name}-igw"
  nat_name = "${var.project_name}-nat"
}

module "security_groups" {
  source = "./modules/security-groups"
  vpc_id = module.vpc.vpc_id
  
  security_group_names = {
    alb   = "${var.project_name}-alb-sg"
  }
}

  module "iam" {
    source                  = "./modules/iam"
    cluster_name            = var.project_name
    aws_region              = var.aws_region
    # cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
    sqs_queue_arn           = module.sqs.queue_arn
    sqs_dlq_arn             = module.sqs.dlq_arn
}

module "eks" {
  source           = "./modules/eks"
  cluster_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  private_subnets  = module.vpc.private_subnet_ids
  cluster_role_arn = module.iam.cluster_role_arn
  node_role_arn    = module.iam.node_role_arn
}

module "ecr" {
  source = "./modules/ecr"

  mutability = "IMMUTABLE"

  services = [
    "natours-frontend",
    "natours-api-gateway",
    "natours-auth-service",
    "natours-tour-service",
    "natours-review-service",
    "natours-booking-service",
    "natours-notification-service"
  ]

  image_count_to_keep = 10
}

module "sqs" {
  source          = "./modules/sqs"
  queue_name      = var.project_name
}

module "pod-identity" {
  source = "./modules/pod-identity"

  cluster_name = module.eks.cluster_name

  associations = {
    alb_controller = {
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
      role_arn        = module.iam.alb_controller_role_arn
    }
    booking_service = {
      namespace       = "default"
      service_account = "booking-service-sa"
      role_arn        = module.iam.booking_service_role_arn
    }
    notification_service = {
      namespace       = "default"
      service_account = "notification-service-sa"
      role_arn        = module.iam.notification_service_role_arn
    }
    all_services = {
      namespace       = "default"
      service_account = "all-services-sa"
      role_arn        = module.iam.all_services_role_arn
    }
  }

  depends_on = [module.eks]
}
