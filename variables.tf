variable "domain_name" {
    description = "FQDN for site"
    type        = string
}

variable "zone_id" {
    description = "Route 53 Zone id"
    type        = string
}

variable "enable_site" {
    description = "Create a static site asset bucket and route default requests to it"
    type        = bool
    default     = false
}

variable "enable_data" {
    description = "Create a separate data bucket and route /data requests to it"
    type        = bool
    default     = false
}

variable "api_gateway" {
    description = "Create a separate data bucket and route /data requests to it"
    type        = bool
    default     = false
}