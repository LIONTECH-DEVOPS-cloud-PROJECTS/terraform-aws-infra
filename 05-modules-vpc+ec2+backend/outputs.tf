output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "ec2_instance_ids" {
  description = "IDs of EC2 instances"
  value       = aws_instance.main[*].id
}

output "ec2_instance_public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = aws_instance.main[*].public_ip
}

output "ec2_instance_private_ips" {
  description = "Private IP addresses of EC2 instances"
  value       = aws_instance.main[*].private_ip
}

output "security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2.id
}