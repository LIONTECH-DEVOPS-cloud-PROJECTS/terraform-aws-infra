# Configure the AWS Provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # This will be configured separately
    # bucket = "your-terraform-state-bucket"
    # key    = "terraform.tfstate"
    # region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# Basic S3 Bucket
resource "aws_s3_bucket" "basic_bucket" {
  bucket = "${var.bucket_prefix}-basic-${var.environment}-${random_id.suffix.hex}"

  tags = merge(var.common_tags, {
    Name = "Basic S3 Bucket"
    Type = "basic"
  })
}

resource "aws_s3_bucket_ownership_controls" "basic_bucket" {
  bucket = aws_s3_bucket.basic_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "basic_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.basic_bucket]

  bucket = aws_s3_bucket.basic_bucket.id
  acl    = "private"
}

# S3 Bucket with Versioning
resource "aws_s3_bucket" "versioned_bucket" {
  bucket = "${var.bucket_prefix}-versioned-${var.environment}-${random_id.suffix.hex}"

  tags = merge(var.common_tags, {
    Name = "Versioned S3 Bucket"
    Type = "versioned"
  })
}

resource "aws_s3_bucket_acl" "versioned_bucket" {
  bucket = aws_s3_bucket.versioned_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioned_bucket" {
  bucket = aws_s3_bucket.versioned_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket with Server Side Encryption
resource "aws_s3_bucket" "encrypted_bucket" {
  bucket = "${var.bucket_prefix}-encrypted-${var.environment}-${random_id.suffix.hex}"

  tags = merge(var.common_tags, {
    Name = "Encrypted S3 Bucket"
    Type = "encrypted"
  })
}

resource "aws_s3_bucket_acl" "encrypted_bucket" {
  bucket = aws_s3_bucket.encrypted_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypted_bucket" {
  bucket = aws_s3_bucket.encrypted_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket with Lifecycle Rules
resource "aws_s3_bucket" "lifecycle_bucket" {
  bucket = "${var.bucket_prefix}-lifecycle-${var.environment}-${random_id.suffix.hex}"

  tags = merge(var.common_tags, {
    Name = "Lifecycle S3 Bucket"
    Type = "lifecycle"
  })
}

resource "aws_s3_bucket_acl" "lifecycle_bucket" {
  bucket = aws_s3_bucket.lifecycle_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_bucket" {
  bucket = aws_s3_bucket.lifecycle_bucket.id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# S3 Bucket with Public Access Block (Secure)
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "${var.bucket_prefix}-secure-${var.environment}-${random_id.suffix.hex}"

  tags = merge(var.common_tags, {
    Name = "Secure S3 Bucket"
    Type = "secure"
  })
}

resource "aws_s3_bucket_acl" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket for Logging (Access Logs)
resource "aws_s3_bucket" "logging_bucket" {
  bucket = "${var.bucket_prefix}-logs-${var.environment}-${random_id.suffix.hex}"

  tags = merge(var.common_tags, {
    Name = "Logging S3 Bucket"
    Type = "logging"
  })
}

resource "aws_s3_bucket_acl" "logging_bucket" {
  bucket = aws_s3_bucket.logging_bucket.id
  acl    = "log-delivery-write"
}

# Configure logging for the secure bucket
resource "aws_s3_bucket_logging" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  target_bucket = aws_s3_bucket.logging_bucket.id
  target_prefix = "logs/"
}

# Random suffix for unique bucket names
resource "random_id" "suffix" {
  byte_length = 4
}