# Terraform VPC and EC2 Module

This Terraform module creates a complete VPC infrastructure with public and private subnets, and deploys EC2 instances within the VPC.

## Features

- VPC with configurable CIDR block
- Public and private subnets across multiple availability zones
- Internet Gateway for public subnets
- NAT Gateway for private subnets (optional)
- Route tables and associations
- Security groups for EC2 instances
- EC2 instances with configurable parameters
- Elastic IP association (optional)

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Update the variables in `terraform.tfvars` with your values
3. Initialize Terraform:
   ```bash
   terraform init