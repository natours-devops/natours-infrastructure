output "vpc_id" {
  value = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = [for k, v in aws_subnet.this : v.id if !var.subnets[k].public]
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for k, v in aws_subnet.this : v.id if var.subnets[k].public]
}