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

# Create IAM users with specific names
resource "aws_iam_user" "class32_users" {
  for_each = toset(["elvis", "john", "mary", "paul", "james"])
  name     = each.key

  tags = {
    Group = "class32-infra"
  }
}

# Add users to the group
resource "aws_iam_group_membership" "class32_members" {
  name = "class32-infra-membership"
  users = [for user in aws_iam_user.class32_users : user.name]
  group = aws_iam_group.class32_infra.name
}

# Create login profiles for console access (without PGP encryption)
resource "aws_iam_user_login_profile" "user_login" {
  for_each = aws_iam_user.class32_users

  user    = each.value.name
  password_reset_required = true
  password_length         = 16
}

# IAM password policy for security
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 12
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 5
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

# Policy for basic console access (list accounts, etc.)
data "aws_iam_policy_document" "basic_console_access" {
  statement {
    effect = "Allow"
    actions = [
      "iam:ListAccountAliases",
      "iam:ListUsers",
      "iam:GetAccountPasswordPolicy",
      "iam:GetAccountSummary"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "basic_console_access_policy" {
  name        = "BasicConsoleAccess"
  description = "Basic permissions for AWS console access"
  policy      = data.aws_iam_policy_document.basic_console_access.json
}

resource "aws_iam_group_policy_attachment" "console_access" {
  group      = aws_iam_group.class32_infra.name
  policy_arn = aws_iam_policy.basic_console_access_policy.arn
}

# Simplified MFA policy - using AWS managed policy instead
resource "aws_iam_group_policy_attachment" "view_only_access" {
  group      = aws_iam_group.class32_infra.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

# Alternative: Create a simpler MFA enforcement policy
data "aws_iam_policy_document" "mfa_policy" {
  statement {
    sid    = "AllowViewAccountInfo"
    effect = "Allow"
    actions = [
      "iam:GetAccountPasswordPolicy",
      "iam:ListVirtualMFADevices"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowManageOwnVirtualMFADevice"
    effect = "Allow"
    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice"
    ]
    resources = ["arn:aws:iam::*:mfa/$${aws:username}"]
  }

  statement {
    sid    = "AllowManageOwnUserMFA"
    effect = "Allow"
    actions = [
      "iam:DeactivateMFADevice",
      "iam:EnableMFADevice",
      "iam:ListMFADevices",
      "iam:ResyncMFADevice"
    ]
    resources = ["arn:aws:iam::*:user/$${aws:username}"]
  }

  statement {
    sid       = "DenyAllExceptListedIfNoMFA"
    effect    = "Deny"
    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "iam:ChangePassword",
      "iam:GetAccountPasswordPolicy"
    ]
    resources = ["*"]
    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_iam_policy" "mfa_policy" {
  name        = "MFAPolicy"
  description = "Policy to enforce MFA usage"
  policy      = data.aws_iam_policy_document.mfa_policy.json
}

resource "aws_iam_group_policy_attachment" "mfa_policy_attachment" {
  group      = aws_iam_group.class32_infra.name
  policy_arn = aws_iam_policy.mfa_policy.arn
}

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

output "user_names" {
  description = "List of created usernames"
  value       = [for user in aws_iam_user.class32_users : user.name]
}

output "console_login_url" {
  description = "AWS console login URL"
  value       = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
}

output "user_passwords" {
  description = "Passwords for users (will be shown in plain text)"
  value       = { for k, v in aws_iam_user_login_profile.user_login : k => v.password }
  sensitive   = true
}

# Get current account ID for console URL
data "aws_caller_identity" "current" {}