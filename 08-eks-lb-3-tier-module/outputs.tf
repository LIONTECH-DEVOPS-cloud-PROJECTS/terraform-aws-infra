# EKS Cluster Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

# Bastion Host Outputs
output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i ${var.bastion_key_pair}.pem ec2-user@${aws_instance.bastion.public_ip}"
  sensitive   = true
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of Application Load Balancer"
  value       = aws_lb.main.zone_id
}

# IAM Users Outputs
output "eks_users" {
  description = "Map of created IAM users for EKS access"
  value       = aws_iam_user.eks_users
}

# Kubeconfig Output - FIXED VERSION
output "kubeconfig" {
  description = "Kubernetes configuration file"
  value = {
    apiVersion = "v1"
    clusters = [{
      name = module.eks.cluster_name
      cluster = {
        certificate-authority-data = module.eks.cluster_certificate_authority_data
        server                     = module.eks.cluster_endpoint
      }
    }]
    contexts = [{
      name = module.eks.cluster_name
      context = {
        cluster = module.eks.cluster_name
        user    = "terraform"
      }
    }]
    current-context = module.eks.cluster_name
    kind            = "Config"
    users = [{
      name = "terraform"
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          args = [
            "eks",
            "get-token",
            "--cluster-name",
            module.eks.cluster_name,
            "--region",
            var.region
          ]
          command = "aws"
        }
      }
    }]
  }
  sensitive = true
}

# Node Group Outputs - FIXED VERSION
output "node_group_arns" {
  description = "ARNs of EKS node groups"
  value       = { for k, v in module.eks.eks_managed_node_groups : k => v.node_group_arn }
}

output "node_group_ids" {
  description = "IDs of EKS node groups"
  value       = { for k, v in module.eks.eks_managed_node_groups : k => v.node_group_id }
}

# Cluster Security Group Outputs
output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS node groups"
  value       = module.eks.node_security_group_id
}