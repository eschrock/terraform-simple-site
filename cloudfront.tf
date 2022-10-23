#
# Configure cloudfront with a subset of the following paths:
#
#   /api    Points to API gateway (enable_api = true)
#   /data   Points to data bucket (enable_data = true)
#   /       Points to site assets (enable_site = true)
#

resource "aws_cloudfront_origin_access_identity" "web" {
    comment = var.domain_name
}

resource "aws_cloudfront_distribution" "web" {
    # Static site origin
    origin {
        domain_name = aws_s3_bucket.site.bucket_regional_domain_name
        origin_id   = "site"

        s3_origin_config {
            origin_access_identity = aws_cloudfront_origin_access_identity.web.cloudfront_access_identity_path
        }
    }

    # Data origin
    dynamic "origin" {
        for_each = var.enable_data ? [1] : []
        content {
            domain_name = aws_s3_bucket.data[0].bucket_regional_domain_name
            origin_id   = "data"

            s3_origin_config {
                origin_access_identity = aws_cloudfront_origin_access_identity.web.cloudfront_access_identity_path
            }
        }
    }

    # API origin
    dynamic "origin" {
        for_each = var.api_lambda_arn != null ? [1] : []
        content {
            domain_name = replace(module.api_gateway.default_apigatewayv2_stage_invoke_url, "/^https?://([^/]*).*/", "$1")
            origin_id   = "api"

            custom_origin_config {
                http_port              = 80
                https_port             = 443
                origin_protocol_policy = "https-only"
                origin_ssl_protocols   = ["TLSv1.2"]
            }
        }
    }

    logging_config {
        include_cookies = false
        bucket          = aws_s3_bucket.logs.bucket_domain_name
        prefix          = "prod"
    }
   
    aliases = [ var.domain_name ]

    enabled             = true
    is_ipv6_enabled     = true
    comment             = var.domain_name
    default_root_object = "index.html"
    price_class         = "PriceClass_100"

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    viewer_certificate {
        acm_certificate_arn = aws_acm_certificate.web.arn
        ssl_support_method  = "sni-only"
        minimum_protocol_version = "TLSv1.2_2018"
    }

    # Serve default content from static S3 bucket
    default_cache_behavior {
        target_origin_id        = "site"
        viewer_protocol_policy  = "redirect-to-https"
        
        default_ttl             = 5400
        min_ttl                 = 3600
        max_ttl                 = 86400
        
        allowed_methods         = [ "GET", "HEAD", "OPTIONS" ]
        cached_methods          = [ "GET", "HEAD" ]
        compress                = true

        forwarded_values {
            query_string = false

            cookies {
                forward = "none"
            }
        }

        lambda_function_association {
            event_type   = "viewer-request"
            lambda_arn   = module.lambda_rewrite.lambda_function_qualified_arn
            include_body = false
        }
    }

    # Data cache behavior
    dynamic "ordered_cache_behavior" {
        for_each = var.enable_data ? [1] : []
        content {
            path_pattern            = "/data/*"
            target_origin_id        = "data"
            viewer_protocol_policy  = "redirect-to-https"
            
            default_ttl             = 5400
            min_ttl                 = 3600
            max_ttl                 = 86400
            
            allowed_methods         = [ "GET", "HEAD", "OPTIONS" ]
            cached_methods          = [ "GET", "HEAD" ]
            compress                = true

            forwarded_values {
                query_string = false

                cookies {
                    forward = "none"
                }
            }
        }
    }

    # API cache behavior
    dynamic "ordered_cache_behavior" {
        for_each = var.api_lambda_arn != null ? [1] : []
        content {
            path_pattern     = "/api/*"
            allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
            cached_methods   = ["GET", "HEAD"]
            target_origin_id = "api"

            default_ttl = 0
            min_ttl     = 0
            max_ttl     = 0

            forwarded_values {
                query_string = true
                cookies {
                    forward = "all"
                }
            }

            viewer_protocol_policy = "redirect-to-https"
        }
    }
}

# Site access
data "aws_iam_policy_document" "site" {
    statement {
        actions   = [ "s3:GetObject" ]
        resources = [ "${aws_s3_bucket.site.arn}/*" ]

        principals {
            type        = "AWS"
            identifiers = [ aws_cloudfront_origin_access_identity.web.iam_arn ]
        }
    }
}

resource "aws_s3_bucket_policy" "site" {
    bucket = aws_s3_bucket.site.id
    policy = data.aws_iam_policy_document.site.json
}


# Data access
data "aws_iam_policy_document" "data" {
    count = var.enable_data ? 1 : 0
    statement {
        actions   = [ "s3:GetObject" ]
        resources = [ "${aws_s3_bucket.data[count.index].arn}/*" ]

        principals {
            type        = "AWS"
            identifiers = [ aws_cloudfront_origin_access_identity.web.iam_arn ]
        }
    }
}

resource "aws_s3_bucket_policy" "data" {
    count = var.enable_data ? 1 : 0
    bucket = aws_s3_bucket.data[count.index].id
    policy = data.aws_iam_policy_document.data[count.index].json
}
