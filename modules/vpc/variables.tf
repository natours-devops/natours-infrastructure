variable "vpc_cidr" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
    public            = bool
  }))
}

variable "igw_name" {
  type = string
}

variable "rt_public_name" {
  type = string
}

variable "rt_private_name" {
  type = string
}

variable "nat_name" {
  type = string
}



