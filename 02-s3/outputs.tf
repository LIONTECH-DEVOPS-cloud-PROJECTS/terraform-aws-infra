output "sept30_8000_bucket_id" {
  description = "ID of the sept30-8000 S3 bucket"
  value       = aws_s3_bucket.sept30_8000.id
}

output "sept30_8000_bucket_arn" {
  description = "ARN of the sept30-8000 S3 bucket"
  value       = aws_s3_bucket.sept30_8000.arn
}

output "bucket_url" {
  description = "URL of the S3 bucket"
  value       = "https://${aws_s3_bucket.sept30_8000.bucket}.s3.amazonaws.com"
}
