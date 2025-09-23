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
resource "aws_iam_group" "ec2_group" {
  name = "ec2-group"
}

# Create IAM users
resource "aws_iam_user" "paul" {
  name = "paul"
}

resource "aws_iam_user" "james" {
  name = "james"
}

resource "aws_iam_user" "che" {
  name = "che"
}

# Add users to the EC2 group
resource "aws_iam_group_membership" "ec2_group_members" {
  name = "ec2-group-membership"

  users = [
    aws_iam_user.paul.name,
    aws_iam_user.james.name,
    aws_iam_user.che.name,
  ]

  group = aws_iam_group.ec2_group.name
}

# Attach the AWS managed EC2 ReadOnly access policy to the group
resource "aws_iam_group_policy_attachment" "ec2_readonly" {
  group      = aws_iam_group.ec2_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# Optional: Create login profiles for users (if you want console access)
# Note: This will create passwords - handle with care!
/*
resource "aws_iam_user_login_profile" "paul_login" {
  user    = aws_iam_user.paul.name
  pgp_key = "keybase:username" # Optional: encrypt password with PGP
}

resource "aws_iam_user_login_profile" "james_login" {
  user    = aws_iam_user.james.name
  pgp_key = "keybase:username"
}

resource "aws_iam_user_login_profile" "che_login" {
  user    = aws_iam_user.che.name
  pgp_key = "keybase:username"
}
*/

# Output the group and user information
output "group_name" {
  description = "The name of the created IAM group"
  value       = aws_iam_group.ec2_group.name
}

output "group_members" {
  description = "List of users in the EC2 group"
  value       = aws_iam_group_membership.ec2_group_members.users
}

output "user_arns" {
  description = "ARNs of the created IAM users"
  value = {
    paul  = aws_iam_user.paul.arn
    james = aws_iam_user.james.arn
    che   = aws_iam_user.che.arn
  }
}

output "attached_policy" {
  description = "The policy attached to the EC2 group"
  value       = aws_iam_group_policy_attachment.ec2_readonly.policy_arn
}