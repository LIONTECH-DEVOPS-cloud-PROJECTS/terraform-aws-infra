terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# IAM Groups
resource "aws_iam_group" "groups" {
  for_each = var.groups

  name = each.key
  path = var.group_path

#   tags = merge(var.tags, {
#     Group = each.key
#   })
}

# IAM Group Policies
resource "aws_iam_group_policy_attachment" "group_policies" {
  for_each = local.group_policies

  group      = each.value.group
  policy_arn = each.value.policy_arn

  depends_on = [aws_iam_group.groups]
}

# IAM Users
resource "aws_iam_user" "users" {
  for_each = var.users

  name          = each.key
  path          = var.user_path
  force_destroy = var.force_destroy_users

  tags = merge(var.tags, {
    User = each.key
  })
}

# IAM User Group Memberships
resource "aws_iam_user_group_membership" "user_groups" {
  for_each = var.users

  user = each.key

  groups = flatten([
    each.value.groups,
    var.default_groups
  ])

  depends_on = [
    aws_iam_user.users,
    aws_iam_group.groups
  ]
}

# IAM User Login Profiles (Console Access)
resource "aws_iam_user_login_profile" "console_access" {
  for_each = local.users_with_console_access

  user                    = each.key
  password_reset_required = each.value.password_reset_required
  password_length         = var.password_length

  # Optional: Set custom password if provided
  # password = each.value.password

  depends_on = [aws_iam_user.users]

  lifecycle {
    ignore_changes = [
      password_reset_required
    ]
  }
}

# IAM Access Keys (Programmatic Access)
resource "aws_iam_access_key" "programmatic_access" {
  for_each = local.users_with_programmatic_access

  user = each.key

  depends_on = [aws_iam_user.users]

  lifecycle {
    ignore_changes = [
      status
    ]
  }
}

# IAM User Policies (Inline Policies)
resource "aws_iam_user_policy" "inline_policies" {
  for_each = local.user_inline_policies

  name   = each.value.name
  user   = each.key
  policy = each.value.policy

  depends_on = [aws_iam_user.users]
}

# IAM User Policy Attachments
resource "aws_iam_user_policy_attachment" "user_policies" {
  for_each = local.user_policy_attachments

  user       = each.key
  policy_arn = each.value.policy_arn

  depends_on = [aws_iam_user.users]
}

# IAM Password Policy
resource "aws_iam_account_password_policy" "strict" {
  count = var.enable_password_policy ? 1 : 0

  minimum_password_length        = var.password_policy.minimum_length
  require_lowercase_characters   = var.password_policy.require_lowercase
  require_uppercase_characters   = var.password_policy.require_uppercase
  require_numbers                = var.password_policy.require_numbers
  require_symbols                = var.password_policy.require_symbols
  allow_users_to_change_password = var.password_policy.allow_change
  max_password_age               = var.password_policy.max_age
  password_reuse_prevention      = var.password_policy.reuse_prevention
  hard_expiry                    = var.password_policy.hard_expiry
}