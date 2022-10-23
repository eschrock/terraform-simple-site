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

variable "api_lambda_arn" {
    description = "If set, create an api gateway and route /api requests to it"
    type        = string
    default     = null
}