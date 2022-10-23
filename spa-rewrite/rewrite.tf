# With a client-side single-page app, explicitly requesting a page like "/Foo" will look for a file named
# "Foo" in our S3 bucket, even though that is a route interpreted on the client side. This results in a 404 error.data 
# To work around this, we want to translate routes into /index.html requests, but only for static (non-API) content.data
# We therefore can't use the built-in CloudFront error translation, because that would also convert our 404 errors from
# the API. Instead, we have to use a Lambda@Edge function to do the translation dynamically anything that doesn't
# have a "." in its name (e.g. index.html, image.png, etc).
module "lambda_error_rewrite" {
  source    = "terraform-aws-modules/lambda/aws"
  version   = "~> 2.0"

  function_name = "${var.domain_name}-rewrite"
  description   = "Rewrite client-side routes for static content"
  handler = "rewrite.handler"
  runtime = "nodejs16.x"

  source_path = "rewrite-handler"

  lambda_at_edge = true
}
