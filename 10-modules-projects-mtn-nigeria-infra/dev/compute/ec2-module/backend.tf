terraform {
  backend "s3" {
    # You'll need to update these values with your actual S3 bucket
    bucket = "september300"
    key    = "terraform/terraform-modules-compute/terraform.tfstate"
    region = "us-east-1"
    
    # Optional: Use DynamoDB for state locking
    # dynamodb_table = "terraform-state-lock"
  }
}