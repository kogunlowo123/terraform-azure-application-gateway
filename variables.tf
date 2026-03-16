variable "name" {
  description = "Name of the Application Gateway."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region for deployment."
  type        = string
}

variable "sku_tier" {
  description = "SKU tier for the Application Gateway (Standard_v2 or WAF_v2)."
  type        = string
  default     = "WAF_v2"

  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.sku_tier)
    error_message = "SKU tier must be Standard_v2 or WAF_v2."
  }
}

variable "sku_capacity" {
  description = "Static instance count (ignored when autoscaling is enabled)."
  type        = number
  default     = 2
}

variable "autoscale_min_capacity" {
  description = "Minimum autoscale capacity."
  type        = number
  default     = 1
}

variable "autoscale_max_capacity" {
  description = "Maximum autoscale capacity."
  type        = number
  default     = 10
}

variable "enable_autoscaling" {
  description = "Enable autoscaling for the Application Gateway."
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "Subnet ID for the Application Gateway."
  type        = string
}

variable "public_ip_id" {
  description = "Public IP address resource ID for the frontend."
  type        = string
}

variable "waf_enabled" {
  description = "Enable Web Application Firewall."
  type        = bool
  default     = true
}

variable "waf_mode" {
  description = "WAF mode (Detection or Prevention)."
  type        = string
  default     = "Prevention"
}

variable "waf_rule_set_version" {
  description = "OWASP rule set version."
  type        = string
  default     = "3.2"
}

variable "waf_file_upload_limit_mb" {
  description = "WAF file upload limit in MB."
  type        = number
  default     = 100
}

variable "waf_max_request_body_size_kb" {
  description = "WAF max request body size in KB."
  type        = number
  default     = 128
}

variable "ssl_certificates" {
  description = "Map of SSL certificates for TLS termination."
  type = map(object({
    key_vault_secret_id = optional(string)
    data                = optional(string)
    password            = optional(string)
  }))
  default = {}
}

variable "trusted_root_certificates" {
  description = "Map of trusted root certificates for end-to-end TLS."
  type = map(object({
    key_vault_secret_id = optional(string)
    data                = optional(string)
  }))
  default = {}
}

variable "backend_address_pools" {
  description = "Map of backend address pools."
  type = map(object({
    fqdns        = optional(list(string), [])
    ip_addresses = optional(list(string), [])
  }))
}

variable "backend_http_settings" {
  description = "Map of backend HTTP settings."
  type = map(object({
    port                    = number
    protocol                = string
    cookie_based_affinity   = optional(string, "Disabled")
    request_timeout         = optional(number, 30)
    pick_host_name          = optional(bool, false)
    probe_name              = optional(string)
    trusted_root_cert_names = optional(list(string), [])
  }))
}

variable "health_probes" {
  description = "Map of health probes."
  type = map(object({
    protocol            = string
    path                = string
    host                = optional(string)
    interval            = optional(number, 30)
    timeout             = optional(number, 30)
    unhealthy_threshold = optional(number, 3)
    pick_host_name      = optional(bool, false)
    match_status_codes  = optional(list(string), ["200-399"])
  }))
  default = {}
}

variable "http_listeners" {
  description = "Map of HTTP listeners."
  type = map(object({
    frontend_ip_configuration_name = optional(string, "public")
    frontend_port_name             = string
    protocol                       = string
    host_names                     = optional(list(string))
    ssl_certificate_name           = optional(string)
    require_sni                    = optional(bool, false)
  }))
}

variable "request_routing_rules" {
  description = "Map of request routing rules."
  type = map(object({
    rule_type                   = optional(string, "Basic")
    priority                    = number
    http_listener_name          = string
    backend_address_pool_name   = optional(string)
    backend_http_settings_name  = optional(string)
    redirect_configuration_name = optional(string)
    url_path_map_name           = optional(string)
  }))
}

variable "redirect_configurations" {
  description = "Map of redirect configurations."
  type = map(object({
    redirect_type        = string
    target_listener_name = optional(string)
    target_url           = optional(string)
    include_path         = optional(bool, true)
    include_query_string = optional(bool, true)
  }))
  default = {}
}

variable "rewrite_rule_sets" {
  description = "Map of rewrite rule sets."
  type = map(list(object({
    name          = string
    rule_sequence = number
    conditions = optional(list(object({
      variable    = string
      pattern     = string
      ignore_case = optional(bool, true)
      negate      = optional(bool, false)
    })), [])
    request_header_configurations = optional(list(object({
      header_name  = string
      header_value = string
    })), [])
    response_header_configurations = optional(list(object({
      header_name  = string
      header_value = string
    })), [])
    url = optional(object({
      path         = optional(string)
      query_string = optional(string)
      reroute      = optional(bool, false)
    }))
  })))
  default = {}
}

variable "frontend_ports" {
  description = "Map of frontend port names to port numbers."
  type        = map(number)
  default = {
    "http"  = 80
    "https" = 443
  }
}

variable "zones" {
  description = "Availability zones for the Application Gateway."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "enable_http2" {
  description = "Enable HTTP/2 protocol."
  type        = bool
  default     = true
}

variable "identity_ids" {
  description = "List of user-assigned managed identity IDs."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
