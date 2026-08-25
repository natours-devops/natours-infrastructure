module "vpc" {
  source = "./modules/vpc"

  vpc_cidr = "10.0.0.0/16"
  vpc_name = "natours_vpc"

  subnets = {
    "natours-public-us-east-1a" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
      public            = true
    }

    "natours-public-us-east-1b" = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1b"
      public            = true
    }

    "natours-private-us-east-1a" = {
      cidr_block        = "10.0.3.0/24"
      availability_zone = "us-east-1a"
      public            = false
    }

    "natours-private-us-east-1b" = {
      cidr_block        = "10.0.4.0/24"
      availability_zone = "us-east-1b"
      public            = false
    }
  }
  
  rt_public_name = "natours_public_rt"
  rt_private_name = "natours_private_rt"
  igw_name = "natours-igw"
  nat_name = "natours-nat"
}