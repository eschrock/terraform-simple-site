variable "domain_name" {
    description = "FQDN for site"
    type        = string
}

variable "zone_id" {
    description = "Route 53 Zone id"
    type        = string
}

variable "enable_data" {
    description = "Create a separate data bucket and route /data requests to it"
    type        = bool
    default     = false
}

variable "enable_api" {
    description = "Create an api gateway and route /api requests to it"
    type        = bool
    default     = false
}

variable "api_lambda_arn" {
    description = "Required if enable_api = true. Route /api requests to this lambda"
    type        = string
    default     = null
}

variable "enable_auth" {
    description = "Enable JWT authentication by default. jwt_audience and jwt_issuer must be set"
    type        = bool
    default     = false
}

variable "jwt_audience" {
    description = "JWT audience configuration. Required if enable_auth is set to true"
    type        = string
    default     = null
}

variable "jwt_issuer" {
    description = "JWT issuer configuration. Required if enable_auth is set to true"
    type        = string
    default     = null
}

variable "unauth_route" {
    description = "optional route to bypass authentication when enable_auth is true"
    type        = string
    default     = "/dev/null"
}