output "s3_bucket_logs" {
  value = aws_s3_bucket.logs.bucket 
}

output "s3_bucket_site" {
  value = var.enable_site ? aws_s3_bucket.site[0].bucket : null
}

output "s3_bucket_data" {
  value = var.enable_data ? aws_s3_bucket.data[0].bucket : null
}