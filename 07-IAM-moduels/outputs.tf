# IAM Groups Outputs
output "groups" {
  description = "Map of created IAM groups"
  value       = aws_iam_group.groups
}

# IAM Users Outputs
output "users" {
  description = "Map of created IAM users"
  value       = aws_iam_user.users
  sensitive   = true
}

# Console Access Outputs
output "console_login_profiles" {
  description = "Map of IAM user login profiles for console access"
  value       = aws_iam_user_login_profile.console_access
  sensitive   = true
}

# Programmatic Access Outputs
output "access_keys" {
  description = "Map of IAM access keys for programmatic access"
  value       = aws_iam_access_key.programmatic_access
  sensitive   = true
}

# Passwords (sensitive - use with caution)
output "passwords" {
  description = "Map of generated passwords for console access"
  value       = { for k, v in aws_iam_user_login_profile.console_access : k => v.password }
  sensitive   = true
}

# Access Key IDs
output "access_key_ids" {
  description = "Map of access key IDs"
  value       = { for k, v in aws_iam_access_key.programmatic_access : k => v.id }
  sensitive   = true
}

# Secret Access Keys (highly sensitive)
output "secret_access_keys" {
  description = "Map of secret access keys - handle with extreme care"
  value       = { for k, v in aws_iam_access_key.programmatic_access : k => v.secret }
  sensitive   = true
}

# Password Policy
output "password_policy" {
  description = "IAM account password policy"
  value       = try(aws_iam_account_password_policy.strict[0], null)
}