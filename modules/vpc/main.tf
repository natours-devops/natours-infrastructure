resource "aws_vpc" "this" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "this" {
  for_each = var.subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.key
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = var.igw_name
  }
}


//NAT gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.this["natours-public-us-east-1a"].id

  tags = {
    Name = var.nat_name
  }
}

//Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id =  aws_vpc.this.id

  tags = { Name = var.rt_public_name }
}

resource "aws_route" "internet_public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "rt_assoc_pub_1" {
  subnet_id      = aws_subnet.this["natours-public-us-east-1a"].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "rt_assoc_pub_2" {
  subnet_id      = aws_subnet.this["natours-public-us-east-1b"].id
  route_table_id = aws_route_table.public.id
}

//Route table for the private subnets
resource "aws_route_table" "private" {
  vpc_id =  aws_vpc.this.id

  tags = { Name = var.rt_private_name }
}

resource "aws_route" "private_internet" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "rt_assoc_pv_1" {
  subnet_id      = aws_subnet.this["natours-private-us-east-1a"].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "rt_assoc_pv_2" {
  subnet_id      = aws_subnet.this["natours-private-us-east-1b"].id
  route_table_id = aws_route_table.private.id
}