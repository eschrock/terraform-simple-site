# Opinionated AWS website framework

This module provisions a basic set of AWS infrastructure for managing a website. It is not intended
to be general purpose, but is something I've done enough times to warrant creating a reusable
module. It will take the following:

 * A Route53 zone (required)
 * A domain name (required)
 * An API gateway for dynamic APIs (optional)
 * A flag for creating a separate data assets bucket (optional)

It will then configure:

 * A S3 bucket for static site assets
 * A S3 bucket for web logs
 * DNS records and SSL certificates for the domain, given an existing Route53 zone
 * A cloudfront distribution with:
     * `/api` pointing to an API gateway (if provided)
     * `/data` pointing to a separate S3 bucket (if provided)
     * `/` pointing to the site asset bucket
 * A rewrite handler to for single page apps to forward anything without a '.' to `index.html`

 ## Inputs

  * `domain_name` - Required. Fully qualified domain name for the site
  * `zone_id` - Required. Route53 zone ID within which to create DNS records
  * `enable_data` - If set to true, then create a separate S3 bucket and map /data ot it
  * `enable_api` - If set to true, then create an HTTP API gateway mapped to /api
  * `api_lambda_arg` - Required if `enable_api` is set, indicates the lambda to use for all requests