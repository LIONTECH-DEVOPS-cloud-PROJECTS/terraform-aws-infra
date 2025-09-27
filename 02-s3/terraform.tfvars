# Copy this file to terraform.tfvars and update the values

aws_region   = "us-east-1"
environment  = "dev"
project_name = "my-awesome-project"
bucket_prefix = "sept272025"

common_tags = {
  Environment = "dev"
  Project     = "my-awesome-project"
  Team        = "devops"
  CostCenter  = "12345"
}