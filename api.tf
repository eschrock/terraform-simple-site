# If the API lambda ARN is set, then configure the /api namespace to forward all traffic
# to this endpoint. A more complicated API namespace might have multiple entries, but as
# this is just s simple

module "api_log_group" {
  count = var.enable_api ? 1 : 0
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "~> 3.0"

  name              = "${var.domain_name}-api"
  retention_in_days = 120
}

module "api_gateway" {
  count = var.enable_api ? 1 : 0
  source = "terraform-aws-modules/apigateway-v2/aws"

  name                    = "${var.domain_name}-api"
  description             = "${var.domain_name} backend API"
  protocol_type           = "HTTP"
  create_api_domain_name  = false

  integrations = {
    "$default" = {
      lambda_arn = var.api_lambda_arn
    }
  }

  tags = {
    Name = "${var.domain_name}-api"
  }

  default_stage_access_log_destination_arn = module.api_log_group[0].cloudwatch_log_group_arn
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"
}
