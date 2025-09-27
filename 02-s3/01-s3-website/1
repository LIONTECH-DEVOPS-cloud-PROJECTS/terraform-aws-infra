terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}

# S3 Bucket
resource "aws_s3_bucket" "september300" {
  bucket = "september300"
}

# Set bucket to private
resource "aws_s3_bucket_ownership_controls" "september300" {
  bucket = aws_s3_bucket.september300.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "september300" {
  depends_on = [aws_s3_bucket_ownership_controls.september300]
  
  bucket = aws_s3_bucket.september300.id
  acl    = "private"
}

# Block public access (security best practice)
resource "aws_s3_bucket_public_access_block" "september300" {
  bucket = aws_s3_bucket.september300.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "bucket_name" {
  value = aws_s3_bucket.september300.id
}

output "bucket_arn" {
  value = aws_s3_bucket.september300.arn
}
