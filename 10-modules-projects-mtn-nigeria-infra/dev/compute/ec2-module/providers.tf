# AWS Provider configuration
provider "aws" {
  region = var.region    # region  =  us-east-1 
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Terraform   = "true"
      Module      = "ec2-compute"
    }
  }
}

provider "tls" {}

provider "random" {}