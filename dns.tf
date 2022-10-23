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

