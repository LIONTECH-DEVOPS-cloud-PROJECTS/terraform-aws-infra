terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # Comment out kubernetes and helm providers for now
    # kubernetes = {
    #   source  = "hashicorp/kubernetes"
    #   version = "~> 2.23"
    # }
    # helm = {
    #   source  = "hashicorp/helm"
    #   version = "~> 2.11"
    # }
  }
}

provider "aws" {
  region = var.region
}

# VPC Module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  single_nat_gateway   = false
  enable_dns_hostnames = true

  # Subnet tags for EKS
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = var.tags
}

# EKS Cluster with API authentication mode
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # Enable API authentication mode for IAM access entries
  #authentication_mode = "API" # This enables IAM access entries

  # EKS Cluster Security Group
  cluster_security_group_additional_rules = {
    ingress_bastion_ssh = {
      description              = "Allow SSH from bastion host"
      protocol                = "tcp"
      from_port               = 443
      to_port                 = 443
      type                    = "ingress"
      source_security_group_id = aws_security_group.bastion.id
    }
  }

  # EKS Managed Node Group
  eks_managed_node_groups = {
    main = {
      name           = "main-node-group"
      instance_types = var.node_group_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size

      disk_size = var.node_group_disk_size

      # Node Group Security Group
      additional_security_group_rules = {
        ingress_alb_http = {
          description              = "Allow HTTP from ALB"
          protocol                = "tcp"
          from_port               = 30000
          to_port                 = 32768
          type                    = "ingress"
          source_security_group_id = aws_security_group.alb.id
        }
      }

      labels = {
        tier = "application"
      }

      tags = merge(var.tags, {
        Tier = "application"
      })
    }

    # Comment out monitoring node group for simplicity
    # monitoring = {
    #   name           = "monitoring-node-group"
    #   instance_types = ["t3.medium"]
    #   capacity_type  = "ON_DEMAND"

    #   min_size     = 1
    #   max_size     = 3
    #   desired_size = 2

    #   disk_size = 50

    #   labels = {
    #     tier = "monitoring"
    #   }

    #   taints = [
    #     {
    #       key    = "monitoring"
    #       value  = "true"
    #       effect = "NO_SCHEDULE"
    #     }
    #   ]

    #   tags = merge(var.tags, {
    #     Tier = "monitoring"
    #   })
    # }
  }

  # Create IAM roles for users instead of direct IAM user access
  #enable_cluster_creator_admin_permissions = true

  tags = var.tags
}

# Alternative approach: Use aws-auth ConfigMap for IAM user access (more compatible)
# DISABLED - Will configure manually after cluster creation
# resource "kubernetes_config_map" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = yamlencode(concat(
#       [{
#         rolearn  = module.eks.cluster_iam_role_arn
#         username = "system:node:{{EC2PrivateDNSName}}"
#         groups = [
#           "system:bootstrappers",
#           "system:nodes",
#         ]
#       }],
#       [for user_name, user_config in var.eks_users : {
#         rolearn  = aws_iam_user.eks_users[user_name].arn
#         username = user_name
#         groups   = user_config.groups
#       }]
#     ))
#   }

#   depends_on = [module.eks]
# }

# Bastion Host Security Group
resource "aws_security_group" "bastion" {
  name        = "${var.cluster_name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-bastion-sg"
  })
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-alb-sg"
  })
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.bastion_instance_type
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = var.bastion_key_pair

  associate_public_ip_address = true

  user_data = file("${path.module}/userdata/bastion.sh")

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-bastion"
    Tier = "bastion"
  })

  depends_on = [module.vpc]
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-alb"
    Tier = "load-balancer"
  })
}

# # ALB Target Group for NodePort services
# resource "aws_lb_target_group" "nodeport" {
#   name        = "${var.cluster_name}-nodeport"
#   port        = 30000
#   protocol    = "HTTP"
#   vpc_id      = module.vpc.vpc_id
#   target_type = "instance"

#   health_check {
#     enabled             = true
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 5
#     interval            = 30
#     path                = "/healthz"
#     port                = "traffic-port"
#   }

#   tags = merge(var.tags, {
#     Name = "${var.cluster_name}-nodeport-tg"
#   })
# }

# ALB Listener for HTTP
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-http-listener"
  })
}

# ALB Listener for HTTPS (placeholder - requires ACM certificate)
resource "aws_lb_listener" "https" {
  count = var.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-https-listener"
  })
}

# IAM Users for EKS Access (Simplified approach)
resource "aws_iam_user" "eks_users" {
  for_each = var.eks_users

  name = each.key
  path = "/eks/"

  tags = merge(var.tags, {
    User = each.key
    Role = each.value.role
  })
}

# IAM Access Keys for programmatic access
resource "aws_iam_access_key" "eks_users" {
  for_each = aws_iam_user.eks_users

  user = each.value.name
}

# IAM Policy for ALB Controller
resource "aws_iam_policy" "alb_controller" {
  name        = "${var.cluster_name}-ALBControllerPolicy"
  description = "Policy for AWS Load Balancer Controller"

  policy = file("${path.module}/userdata/alb-controller-policy.json")
}

# Attach ALB Controller Policy to Node Group Role
resource "aws_iam_role_policy_attachment" "alb_controller" {
  for_each = module.eks.eks_managed_node_groups

  policy_arn = aws_iam_policy.alb_controller.arn
  role       = each.value.iam_role_name

  depends_on = [module.eks]
}

# DISABLED - Kubernetes and Helm resources (will configure manually after cluster creation)
# Kubernetes Provider Configuration
# data "aws_eks_cluster_auth" "cluster" {
#   name = module.eks.cluster_name
# }

# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#   token                  = data.aws_eks_cluster_auth.cluster.token

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args = [
#       "eks",
#       "get-token",
#       "--cluster-name",
#       module.eks.cluster_name,
#       "--region",
#       var.region
#     ]
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = module.eks.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#     token                  = data.aws_eks_cluster_auth.cluster.token

#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args = [
#         "eks",
#         "get-token",
#         "--cluster-name",
#         module.eks.cluster_name,
#         "--region",
#         var.region
#       ]
#     }
#   }
# }

# DISABLED - AWS Load Balancer Controller (install manually after cluster creation)
# resource "helm_release" "aws_load_balancer_controller" {
#   name       = "aws-load-balancer-controller"
#   repository = "https://aws.github.io/eks-charts"
#   chart      = "aws-load-balancer-controller"
#   namespace  = "kube-system"
#   version    = "1.6.1"

#   set {
#     name  = "clusterName"
#     value = module.eks.cluster_name
#   }

#   set {
#     name  = "serviceAccount.create"
#     value = "false"
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = "aws-load-balancer-controller"
#   }

#   set {
#     name  = "region"
#     value = var.region
#   }

#   set {
#     name  = "vpcId"
#     value = module.vpc.vpc_id
#   }

#   # Add timeout to prevent context deadline exceeded
#   timeout = 600

#   depends_on = [
#     module.eks,
#     kubernetes_config_map.aws_auth
#   ]
# }

# DISABLED - Create ALB Controller Service Account
# resource "kubernetes_service_account" "alb_controller" {
#   metadata {
#     name      = "aws-load-balancer-controller"
#     namespace = "kube-system"
#     labels = {
#       "app.kubernetes.io/name"       = "aws-load-balancer-controller"
#       "app.kubernetes.io/component"  = "controller"
#     }
#     annotations = {
#       "eks.amazonaws.com/role-arn" = module.eks.cluster_iam_role_arn
#     }
#   }

#   depends_on = [module.eks]
# }

# DISABLED - Sample Application Deployment (deploy manually after cluster setup)
# resource "kubernetes_deployment" "sample_app" {
#   count = var.deploy_sample_app ? 1 : 0

#   metadata {
#     name = "sample-app"
#     labels = {
#       app = "sample-app"
#     }
#   }

#   spec {
#     replicas = 2

#     selector {
#       match_labels = {
#         app = "sample-app"
#     }
#   }

#   template {
#     metadata {
#       labels = {
#         app = "sample-app"
#       }
#     }

#     spec {
#       container {
#         image = "nginx:alpine"
#         name  = "nginx"

#         port {
#           container_port = 80
#         }

#         resources {
#           limits = {
#             cpu    = "0.5"
#             memory = "512Mi"
#           }
#           requests = {
#             cpu    = "250m"
#             memory = "50Mi"
#           }
#         }
#       }
#     }
#   }

#   depends_on = [
#     module.eks,
#     kubernetes_config_map.aws_auth
#   ]
# }

# resource "kubernetes_service" "sample_app" {
#   count = var.deploy_sample_app ? 1 : 0

#   metadata {
#     name = "sample-app-service"
#     annotations = {
#       "service.beta.kubernetes.io/aws-load-balancer-type" = "external"
#       "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
#     }
#   }

#   spec {
#     selector = {
#       app = "sample-app"
#     }

#     port {
#       port        = 80
#       target_port = 80
#       protocol    = "TCP"
#     }

#     type = "NodePort"
#   }

#   depends_on = [helm_release.aws_load_balancer_controller]
# }

# Data source for Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}