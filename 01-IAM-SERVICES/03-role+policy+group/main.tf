# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Change to your preferred region
}

# Create the IAM group
resource "aws_iam_group" "class32_infra" {
  name = "class32-infra"
}

# Assume role policy for EC2 service
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Create the IAM role
resource "aws_iam_role" "ec2_only" {
  name               = "ec2-only"
  description        = "Role for EC2 instances with necessary permissions"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name        = "ec2-only-role"
    Environment = "class32"
    Group       = "class32-infra"
  }
}

# Attach common EC2 policies to the role
resource "aws_iam_role_policy_attachment" "ec2_readonly" {
  role       = aws_iam_role.ec2_only.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.ec2_only.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Policy to allow the class32-infra group to assume the ec2-only role
data "aws_iam_policy_document" "assume_ec2_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      aws_iam_role.ec2_only.arn
    ]
  }
}

# Create policy for group to assume the role
resource "aws_iam_policy" "assume_ec2_role_policy" {
  name        = "AssumeEC2OnlyRolePolicy"
  description = "Allows class32-infra group to assume the ec2-only role"
  policy      = data.aws_iam_policy_document.assume_ec2_role.json
}

# Attach the assume role policy to the class32-infra group
resource "aws_iam_group_policy_attachment" "class32_infra_assume_role" {
  group      = aws_iam_group.class32_infra.name
  policy_arn = aws_iam_policy.assume_ec2_role_policy.arn
}

# Optional: Add some users to the group (uncomment if needed)

resource "aws_iam_user" "example_users" {
  for_each = toset(["john", "james", "uuche"])
  name     = each.key
}

resource "aws_iam_group_membership" "class32_members" {
  name = "class32-infra-membership"
  users = [for user in aws_iam_user.example_users : user.name]
  group = aws_iam_group.class32_infra.name
}


# Optional: Custom inline policy for additional permissions (uncomment if needed)
/*
resource "aws_iam_role_policy" "ec2_custom_permissions" {
  name = "EC2CustomPermissions"
  role = aws_iam_role.ec2_only.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      }
    ]
  })
}
*/

# Outputs
output "ec2_only_role_arn" {
  description = "ARN of the created ec2-only role"
  value       = aws_iam_role.ec2_only.arn
}

output "ec2_only_role_name" {
  description = "Name of the created ec2-only role"
  value       = aws_iam_role.ec2_only.name
}

output "class32_infra_group_name" {
  description = "Name of the created class32-infra group"
  value       = aws_iam_group.class32_infra.name
}

output "assume_role_policy_arn" {
  description = "ARN of the policy that allows assuming the ec2-only role"
  value       = aws_iam_policy.assume_ec2_role_policy.arn
}

output "group_attached_policies" {
  description = "List of policies attached to the class32-infra group"
  value       = [aws_iam_policy.assume_ec2_role_policy.arn]
}

output "role_attached_policies" {
  description = "List of policies attached to the ec2-only role"
  value       = [
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}