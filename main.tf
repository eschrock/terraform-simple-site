#
# Configure the site bucket with the following options:
#
#   * Private ACL (cloudfront only)
#   * Server Side encryption
#   * Website enabled
#

resource "aws_s3_bucket" "web" {
    bucket  = "${var.domain_name}-web"
}

resource "aws_s3_bucket_website_configuration" "example" {
    bucket  = aws_s3_bucket.web.bucket

    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "error.html"
    }
}

# Cloudfront logging bucket
resource "aws_s3_bucket" "web_logs" {
    bucket = "${var.domain_name}-web-logs"
}

# Make all buckets private and encrypted
resource "aws_s3_bucket_acl" "web" {
    for_each = toset([
        "${var.domain_name}-web",
        "${var.domain_name}-web-logs"
    ])

    bucket = each.value
    acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "web" {
    for_each = toset([
        "${var.domain_name}-web",
        "${var.domain_name}-web-logs"
    ])

    bucket = each.value
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "web" {
    for_each = toset([
        "${var.domain_name}-web",
        "${var.domain_name}-web-logs"
    ])

    bucket  = each.value
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}


# Configure cloudfront. Currently, this is using the default cloudnfront endpoint, but eventually we will want to
# configure this to use static domain name (and associated HTTPS certificate).

resource "aws_cloudfront_origin_access_identity" "web" {
    comment = var.domain_name
}

resource "aws_cloudfront_distribution" "web" {
    # Serve static content out of our S3 bucket
    origin {
        domain_name = aws_s3_bucket.web.bucket_regional_domain_name
        origin_id   = "static"

        s3_origin_config {
            origin_access_identity = aws_cloudfront_origin_access_identity.web.cloudfront_access_identity_path
        }
    }

    # And API content out of our API gateway
    origin {
        domain_name = aws_route53_record.api.fqdn
        origin_id   = "api"

        custom_origin_config {
            http_port              = 80
            https_port             = 443
            origin_protocol_policy = "https-only"
            origin_ssl_protocols   = ["TLSv1.2"]
        }
    }

    logging_config {
        include_cookies = false
        bucket          = aws_s3_bucket.web_logs.bucket_domain_name
        prefix          = "prod"
    }
   
    aliases = [ var.domain_name ]

    enabled             = true
    is_ipv6_enabled     = true
    comment             = var.domain_name
    default_root_object = "index.html"
    price_class         = "PriceClass_100"

    # Serve default content from static S3 bucket
    default_cache_behavior {
        target_origin_id        = "static"
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
            lambda_arn   = module.lambda_error_rewrite.lambda_function_qualified_arn
            include_body = false
        }
    }

    # Serve API content from API load balancer
    ordered_cache_behavior {
        path_pattern     = "/api/*"
        allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "api"

        default_ttl = 0
        min_ttl     = 0
        max_ttl     = 0

        forwarded_values {
            query_string = true
            headers = [ "Authorization" ]
            cookies {
                forward = "all"
            }
        }

        viewer_protocol_policy = "redirect-to-https"
    }

    # Data is also served from the API, but with caching enabled
    ordered_cache_behavior {
        path_pattern     = "/data/*"
        allowed_methods  = ["GET", "HEAD", "OPTIONS"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "api"

        default_ttl             = 5400
        min_ttl                 = 3600
        max_ttl                 = 86400

        forwarded_values {
            query_string = true
            headers = [ "Authorization" ]
            cookies {
                forward = "all"
            }
        }

        viewer_protocol_policy = "redirect-to-https"
    }

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
}

# Configure the S3 access policy to allow cloudfront access.

data "aws_iam_policy_document" "web" {
    statement {
        actions   = [ "s3:GetObject" ]
        resources = [ "${aws_s3_bucket.web.arn}/*" ]

        principals {
            type        = "AWS"
            identifiers = [ aws_cloudfront_origin_access_identity.web.iam_arn ]
        }
    }
}

resource "aws_s3_bucket_policy" "web" {
    bucket = aws_s3_bucket.web.id
    policy = data.aws_iam_policy_document.web.json
}

# Configure DNS and SSL for the site. We create a DNS record within an existing Route 53 zone. In the future, the full
# zone should be created and managed within this infrastructure. But for now, we're sharing an existing Route 53 zone.

# Main DNS record
resource "aws_route53_record" "web" {
    zone_id         = var.zone_id
    name            = var.domain_name
    type            = "A"

    alias {
        name                    = aws_cloudfront_distribution.web.domain_name
        zone_id                 = aws_cloudfront_distribution.web.hosted_zone_id
        evaluate_target_health  = false
    }
}

# Main SSL certificate
resource "aws_acm_certificate" "web" {
    domain_name = var.domain_name
    subject_alternative_names = [ "*.${var.domain_name}" ]
    validation_method = "DNS"
    lifecycle {
        create_before_destroy = true
    }
}

# Enable certificate validation
resource "aws_acm_certificate_validation" "web" {
    certificate_arn = aws_acm_certificate.web.arn
    validation_record_fqdns = [ for record in aws_route53_record.validation : record.fqdn ]
}

# DNS entries to support validation
resource "aws_route53_record" "validation" {
    for_each = {
        for dvo in aws_acm_certificate.web.domain_validation_options : dvo.domain_name => {
            name   = dvo.resource_record_name
            record = dvo.resource_record_value
            type   = dvo.resource_record_type
        }
    }

    zone_id         = var.zone_id
    allow_overwrite = true
    name            = each.value.name
    records         = [ each.value.record ]
    type            = each.value.type
    ttl             = 300
}

# Because we have a client-side single-page app, explicitly requesting a page like "/Foo" will look for a file named
# "Foo" in our S3 bucket, even though that is a route interpreted on the client side. This results in a 404 error.data 
# To work around this, we want to translate routes into /index.html requests, but only for static (non-API) content.data
# We therefore can't use the built-in CloudFront error translation, because that would also convert our 404 errors from
# the API. Instead, we have to use a Lambda@Edge function to do the translation dynamically only for the static
# origin. Because this is effectively a piece of the infratsructure (and not a separate logical bit of software), we
# deploy the lambda from this repo.
module "lambda_error_rewrite" {
  source    = "terraform-aws-modules/lambda/aws"
  version   = "~> 2.0"

  function_name = "${var.deployment_name}-error-rewrite"
  description   = "Rewrite client-side routes for static content"
  handler = "rewrite.handler"
  runtime = "nodejs16.x"

  source_path = "spa-rewrite"

  lambda_at_edge = true

  store_on_s3 = true
  s3_bucket = module.s3_bucket_api.s3_bucket_id
  s3_prefix = "lambda"

}
