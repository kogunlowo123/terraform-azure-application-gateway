resource "azurerm_web_application_firewall_policy" "this" {
  count = var.waf_enabled ? 1 : 0

  name                = "${var.name}-waf-policy"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    file_upload_limit_in_mb     = var.waf_file_upload_limit_mb
    max_request_body_size_in_kb = var.waf_max_request_body_size_kb
    request_body_check          = true
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = var.waf_rule_set_version
    }

    managed_rule_set {
      type    = "Microsoft_BotManagerRuleSet"
      version = "1.0"
    }
  }

  tags = var.tags
}

resource "azurerm_application_gateway" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  zones               = var.zones
  enable_http2        = var.enable_http2
  firewall_policy_id  = var.waf_enabled ? azurerm_web_application_firewall_policy.this[0].id : null

  tags = var.tags

  sku {
    name = var.sku_tier
    tier = var.sku_tier
  }

  dynamic "autoscale_configuration" {
    for_each = var.enable_autoscaling ? [1] : []
    content {
      min_capacity = var.autoscale_min_capacity
      max_capacity = var.autoscale_max_capacity
    }
  }

  gateway_ip_configuration {
    name      = "appgw-gateway-ip"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = var.public_ip_id
  }

  dynamic "frontend_port" {
    for_each = var.frontend_ports
    content {
      name = frontend_port.key
      port = frontend_port.value
    }
  }

  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                = ssl_certificate.key
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
      data                = ssl_certificate.value.data
      password            = ssl_certificate.value.password
    }
  }

  dynamic "trusted_root_certificate" {
    for_each = var.trusted_root_certificates
    content {
      name                = trusted_root_certificate.key
      key_vault_secret_id = trusted_root_certificate.value.key_vault_secret_id
      data                = trusted_root_certificate.value.data
    }
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = backend_address_pool.key
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = backend_http_settings.key
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      request_timeout                     = backend_http_settings.value.request_timeout
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name
      probe_name                          = backend_http_settings.value.probe_name
      trusted_root_certificate_names      = backend_http_settings.value.trusted_root_cert_names
    }
  }

  dynamic "probe" {
    for_each = var.health_probes
    content {
      name                                      = probe.key
      protocol                                  = probe.value.protocol
      path                                      = probe.value.path
      host                                      = probe.value.host
      interval                                  = probe.value.interval
      timeout                                   = probe.value.timeout
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name

      match {
        status_code = probe.value.match_status_codes
      }
    }
  }

  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = http_listener.key
      frontend_ip_configuration_name = "appgw-frontend-ip"
      frontend_port_name             = http_listener.value.frontend_port_name
      protocol                       = http_listener.value.protocol
      host_names                     = http_listener.value.host_names
      ssl_certificate_name           = http_listener.value.ssl_certificate_name
      require_sni                    = http_listener.value.require_sni
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name                        = request_routing_rule.key
      rule_type                   = request_routing_rule.value.rule_type
      priority                    = request_routing_rule.value.priority
      http_listener_name          = request_routing_rule.value.http_listener_name
      backend_address_pool_name   = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name  = request_routing_rule.value.backend_http_settings_name
      redirect_configuration_name = request_routing_rule.value.redirect_configuration_name
      url_path_map_name           = request_routing_rule.value.url_path_map_name
    }
  }

  dynamic "redirect_configuration" {
    for_each = var.redirect_configurations
    content {
      name                 = redirect_configuration.key
      redirect_type        = redirect_configuration.value.redirect_type
      target_listener_name = redirect_configuration.value.target_listener_name
      target_url           = redirect_configuration.value.target_url
      include_path         = redirect_configuration.value.include_path
      include_query_string = redirect_configuration.value.include_query_string
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = var.rewrite_rule_sets
    content {
      name = rewrite_rule_set.key

      dynamic "rewrite_rule" {
        for_each = rewrite_rule_set.value
        content {
          name          = rewrite_rule.value.name
          rule_sequence = rewrite_rule.value.rule_sequence

          dynamic "condition" {
            for_each = rewrite_rule.value.conditions
            content {
              variable    = condition.value.variable
              pattern     = condition.value.pattern
              ignore_case = condition.value.ignore_case
              negate      = condition.value.negate
            }
          }

          dynamic "request_header_configuration" {
            for_each = rewrite_rule.value.request_header_configurations
            content {
              header_name  = request_header_configuration.value.header_name
              header_value = request_header_configuration.value.header_value
            }
          }

          dynamic "response_header_configuration" {
            for_each = rewrite_rule.value.response_header_configurations
            content {
              header_name  = response_header_configuration.value.header_name
              header_value = response_header_configuration.value.header_value
            }
          }

          dynamic "url" {
            for_each = rewrite_rule.value.url != null ? [rewrite_rule.value.url] : []
            content {
              path         = url.value.path
              query_string = url.value.query_string
              reroute      = url.value.reroute
            }
          }
        }
      }
    }
  }

  dynamic "identity" {
    for_each = length(var.identity_ids) > 0 ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids
    }
  }
}
