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

# Create IAM users
resource "aws_iam_user" "elvis" {
  name = "elvis"
}

resource "aws_iam_user" "john" {
  name = "john"
}

resource "aws_iam_user" "mary" {
  name = "mary"
}

# Add users to the group
resource "aws_iam_group_membership" "class32_infra_members" {
  name = "class32-infra-membership"

  users = [
    aws_iam_user.elvis.name,
    aws_iam_user.john.name,
    aws_iam_user.mary.name,
  ]

  group = aws_iam_group.class32_infra.name
}

# Output the group and user information
output "group_name" {
  value = aws_iam_group.class32_infra.name
}

output "group_members" {
  value = aws_iam_group_membership.class32_infra_members.users
}

output "user_arns" {
  value = {
    elvis = aws_iam_user.elvis.arn
    john  = aws_iam_user.john.arn
    mary  = aws_iam_user.mary.arn
  }
}