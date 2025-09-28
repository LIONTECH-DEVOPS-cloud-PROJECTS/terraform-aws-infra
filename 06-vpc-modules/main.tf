provider "aws" {
  region = var.region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  # Database subnets (optional)
  create_database_subnet_group = var.create_database_subnet_group
  database_subnets = var.database_subnet_cidrs

  # NAT Gateway configuration
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # DNS configuration
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC endpoints
  #enable_s3_endpoint = var.enable_s3_endpoint

  # Tags
  tags = var.tags
}