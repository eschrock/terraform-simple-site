output "s3_bucket_logs" {
  value = aws_s3_bucket.logs.bucket 
}

output "s3_bucket_site" {
  value = aws_s3_bucket.site.bucket
}

output "s3_bucket_data" {
  value = var.enable_data ? aws_s3_bucket.data[0].bucket : null
}

output "api_gateway_arn" {
  value = var.enable_api ? module.api_gateway[0].apigatewayv2_api_execution_arn : null
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.web.arn
}