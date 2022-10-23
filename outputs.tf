output "s3_bucket_logs" {
  value = aws_s3_bucket.logs.bucket 
}

output "s3_bucket_site" {
  value = aws_s3_bucket.site.bucket
}

output "s3_bucket_data" {
  value = var.enable_data ? aws_s3_bucket.data[0].bucket : null
}