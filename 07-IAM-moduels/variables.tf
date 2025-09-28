# AWS Configuration
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# IAM Groups Configuration
variable "groups" {
  description = "Map of IAM groups to create with their configuration"
  type = map(object({
    policies = list(string) # List of policy ARNs to attach to the group
  }))
  default = {
    "Administrators" = {
      policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
    "Developers" = {
      policies = [
        "arn:aws:iam::aws:policy/AmazonS3FullAccess",
        "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
      ]
    }
    "ReadOnly" = {
      policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
  }
}

# IAM Users Configuration
variable "users" {
  description = "Map of IAM users to create with their configuration"
  type = map(object({
    groups                    = list(string)
    enable_console_access     = bool
    enable_programmatic_access = bool
    password_reset_required   = bool
    inline_policies = optional(list(object({
      name   = string
      policy = string
    })), [])
    managed_policies = optional(list(string), [])
  }))
  default = {
    "admin-user" = {
      groups                    = ["Administrators"]
      enable_console_access     = true
      enable_programmatic_access = true
      password_reset_required   = true
      inline_policies           = []
      managed_policies          = []
    }
    "dev-user" = {
      groups                    = ["Developers"]
      enable_console_access     = true
      enable_programmatic_access = true
      password_reset_required   = true
      inline_policies           = []
      managed_policies          = []
    }
  }
}

# Default groups for all users
variable "default_groups" {
  description = "List of groups that all users will be added to by default"
  type        = list(string)
  default     = []
}

# IAM Paths
variable "group_path" {
  description = "Path for IAM groups"
  type        = string
  default     = "/"
}

variable "user_path" {
  description = "Path for IAM users"
  type        = string
  default     = "/"
}

# Password Configuration
variable "password_length" {
  description = "Length of generated passwords for console access"
  type        = number
  default     = 20
}

# Security Settings
variable "force_destroy_users" {
  description = "Whether to force destroy IAM users even if they have resources"
  type        = bool
  default     = false
}

# Password Policy Configuration
variable "enable_password_policy" {
  description = "Whether to enable strict password policy"
  type        = bool
  default     = true
}

variable "password_policy" {
  description = "Configuration for IAM account password policy"
  type = object({
    minimum_length     = number
    require_lowercase  = bool
    require_uppercase  = bool
    require_numbers    = bool
    require_symbols    = bool
    allow_change       = bool
    max_age           = number
    reuse_prevention  = number
    hard_expiry       = bool
  })
  default = {
    minimum_length     = 12
    require_lowercase  = true
    require_uppercase  = true
    require_numbers    = true
    require_symbols    = true
    allow_change       = true
    max_age           = 90
    reuse_prevention  = 3
    hard_expiry       = false
  }
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "iam-management"
  }
}