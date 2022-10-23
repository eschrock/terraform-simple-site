# Opinionated AWS website framework

This module provisions a basic set of AWS infrastructure for managing a website. It is not intended
to be general purpose, but is something I've done enough times to warrant creating a reusable
module. It will provision the following:

 * An S3 bucket for site assets (`<domain>-web-site`)
 * An S3 bucket for site logs (`<domain>-web-logs`)
 * An S3 bucket for site data (`<domain>-web-data`)
 * DNS records and SSL certificates for the domain, given an existing Route53 zone
 * A cloudfront distribution with:
     *  