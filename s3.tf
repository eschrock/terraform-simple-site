#
# Configure S3 buckets for use by the site. There are up to three buckets
# configured by this module:
#
#   <domain>-web-logs   Always configured for Cloudfront logs
#   <domain>-web-site   If enable_site is set, then default static assets are served from here
#   <domain>-web-data   If enable_data is set, then /data assets are served from here
#
# Every bucket is configured to be private with server side encryption. Access is then explicitly
# granted to cloudfront.
#

# Cloudfront logging bucket
resource "aws_s3_bucket" "logs" {
    bucket = "${var.domain_name}-web-logs"
}

resource "aws_s3_bucket_acl" "logs" {
    bucket = aws_s3_bucket.logs.bucket
    acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "logs" {
    bucket                  = aws_s3_bucket.logs.bucket
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
    bucket = aws_s3_bucket.logs.bucket
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}


# Static site bucket
resource "aws_s3_bucket" "site" {
    count  = var.enable_site ? 1 : 0
    bucket = "${var.domain_name}-web-site"
}

resource "aws_s3_bucket_acl" "site" {
    count  = var.enable_site ? 1 : 0
    bucket = aws_s3_bucket.site[count.index].bucket
    acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "site" {
    count                   = var.enable_site ? 1 : 0
    bucket                  = aws_s3_bucket.site[count.index].bucket
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
    count  = var.enable_site ? 1 : 0
    bucket = aws_s3_bucket.site[count.index].bucket
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

resource "aws_s3_bucket_website_configuration" "site" {
    count  = var.enable_site ? 1 : 0
    bucket  = aws_s3_bucket.site[count.index].bucket

    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "error.html"
    }
}

# Static data bucket
resource "aws_s3_bucket" "data" {
    count  = var.enable_data ? 1 : 0
    bucket = "${var.domain_name}-web-data"
}

resource "aws_s3_bucket_acl" "data" {
    count  = var.enable_data ? 1 : 0
    bucket = aws_s3_bucket.data[count.index].bucket
    acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "data" {
    count                   = var.enable_data ? 1 : 0
    bucket                  = aws_s3_bucket.data[count.index].bucket
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
    count  = var.enable_data ? 1 : 0
    bucket = aws_s3_bucket.data[count.index].bucket
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}