output "basic_bucket_id" {
  description = "ID of the basic S3 bucket"
  value       = aws_s3_bucket.basic_bucket.id
}

output "basic_bucket_arn" {
  description = "ARN of the basic S3 bucket"
  value       = aws_s3_bucket.basic_bucket.arn
}

output "versioned_bucket_id" {
  description = "ID of the versioned S3 bucket"
  value       = aws_s3_bucket.versioned_bucket.id
}

output "encrypted_bucket_id" {
  description = "ID of the encrypted S3 bucket"
  value       = aws_s3_bucket.encrypted_bucket.id
}

output "lifecycle_bucket_id" {
  description = "ID of the lifecycle S3 bucket"
  value       = aws_s3_bucket.lifecycle_bucket.id
}

output "secure_bucket_id" {
  description = "ID of the secure S3 bucket"
  value       = aws_s3_bucket.secure_bucket.id
}

output "logging_bucket_id" {
  description = "ID of the logging S3 bucket"
  value       = aws_s3_bucket.logging_bucket.id
}

output "all_buckets" {
  description = "Map of all created S3 buckets"
  value = {
    basic      = aws_s3_bucket.basic_bucket.id
    versioned  = aws_s3_bucket.versioned_bucket.id
    encrypted  = aws_s3_bucket.encrypted_bucket.id
    lifecycle  = aws_s3_bucket.lifecycle_bucket.id
    secure     = aws_s3_bucket.secure_bucket.id
    logging    = aws_s3_bucket.logging_bucket.id
  }
}