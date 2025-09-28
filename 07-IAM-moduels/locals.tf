locals {
  # Users with console access
  users_with_console_access = {
    for user, config in var.users :
    user => config
    if config.enable_console_access
  }

  # Users with programmatic access
  users_with_programmatic_access = {
    for user, config in var.users :
    user => config
    if config.enable_programmatic_access
  }

  # Group policies flattened for attachment
  group_policies = merge([
    for group_name, group_config in var.groups : {
      for policy in group_config.policies :
      "${group_name}-${replace(policy, "/[^a-zA-Z0-9]/", "-")}" => {
        group      = group_name
        policy_arn = policy
      }
    }
  ]...)

  # User inline policies flattened
  user_inline_policies = merge([
    for user_name, user_config in var.users : {
      for policy in user_config.inline_policies :
      "${user_name}-${policy.name}" => {
        user   = user_name
        name   = policy.name
        policy = policy.policy
      }
    }
  ]...)

  # User managed policies flattened
  user_policy_attachments = merge([
    for user_name, user_config in var.users : {
      for policy in user_config.managed_policies :
      "${user_name}-${replace(policy, "/[^a-zA-Z0-9]/", "-")}" => {
        user       = user_name
        policy_arn = policy
      }
    }
  ]...)
}