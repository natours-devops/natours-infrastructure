locals {
  project_name = "natours"
}


module "vpc" {
  source = "./modules/vpc"

  vpc_cidr = "10.0.0.0/16"
  vpc_name = "natours_vpc"

  subnets = {
    "natours-public-us-east-1a" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "${var.aws-region}a"
      public            = true
    }

    "natours-public-us-east-1b" = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "${var.aws-region}b"
      public            = true
    }

    "natours-private-us-east-1a" = {
      cidr_block        = "10.0.3.0/24"
      availability_zone = "${var.aws-region}a"
      public            = false
    }

    "natours-private-us-east-1b" = {
      cidr_block        = "10.0.4.0/24"
      availability_zone = "${var.aws-region}b"
      public            = false
    }
  }
  
  rt_public_name = "natours_public_rt"
  rt_private_name = "natours_private_rt"
  igw_name = "natours-igw"
  nat_name = "natours-nat"
}

module "security_groups" {
  source = "./modules/security-groups"
  vpc_id = module.vpc.vpc_id
  
  security_group_names = {
    alb   = "natours-alb-sg"
  }
}

  module "iam" {
    source                  = "./modules/iam"
    cluster_name            = "natours"
    aws_region              = var.aws_region
    # cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
    sqs_queue_arn           = module.sqs.queue_arn
    sqs_dlq_arn             = module.sqs.dlq_arn
}

module "eks" {
  source           = "./modules/eks"
  cluster_name     = "natours"
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
  source                        = "./modules/sqs"
  project_name                  = "natours"
}