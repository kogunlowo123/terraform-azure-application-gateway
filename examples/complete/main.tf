provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-appgw-complete"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-appgw-complete"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "pip-appgw-complete"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_user_assigned_identity" "appgw" {
  name                = "id-appgw"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

module "application_gateway" {
  source = "../../"

  name                = "appgw-complete"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  subnet_id           = azurerm_subnet.appgw.id
  public_ip_id        = azurerm_public_ip.example.id
  enable_http2        = true
  identity_ids        = [azurerm_user_assigned_identity.appgw.id]

  waf_enabled              = true
  waf_mode                 = "Prevention"
  waf_rule_set_version     = "3.2"
  waf_file_upload_limit_mb = 200

  enable_autoscaling     = true
  autoscale_min_capacity = 2
  autoscale_max_capacity = 10

  frontend_ports = {
    "http"  = 80
    "https" = 443
  }

  backend_address_pools = {
    "app-backend" = {
      fqdns = ["app1.example.com", "app2.example.com"]
    }
    "api-backend" = {
      fqdns = ["api.example.com"]
    }
  }

  backend_http_settings = {
    "https-settings" = {
      port                    = 443
      protocol                = "Https"
      cookie_based_affinity   = "Enabled"
      request_timeout         = 60
      pick_host_name          = true
      probe_name              = "https-probe"
      trusted_root_cert_names = []
    }
    "http-settings" = {
      port     = 80
      protocol = "Http"
    }
  }

  health_probes = {
    "https-probe" = {
      protocol            = "Https"
      path                = "/health"
      pick_host_name      = true
      interval            = 15
      timeout             = 10
      unhealthy_threshold = 3
      match_status_codes  = ["200-299"]
    }
  }

  http_listeners = {
    "http-listener" = {
      frontend_port_name = "http"
      protocol           = "Http"
    }
    "https-app-listener" = {
      frontend_port_name = "https"
      protocol           = "Https"
      host_names         = ["app.example.com"]
      require_sni        = true
    }
    "https-api-listener" = {
      frontend_port_name = "https"
      protocol           = "Https"
      host_names         = ["api.example.com"]
      require_sni        = true
    }
  }

  redirect_configurations = {
    "http-to-https" = {
      redirect_type        = "Permanent"
      target_listener_name = "https-app-listener"
      include_path         = true
      include_query_string = true
    }
  }

  request_routing_rules = {
    "http-redirect" = {
      priority                    = 100
      http_listener_name          = "http-listener"
      redirect_configuration_name = "http-to-https"
    }
    "app-https" = {
      priority                   = 200
      http_listener_name         = "https-app-listener"
      backend_address_pool_name  = "app-backend"
      backend_http_settings_name = "https-settings"
    }
    "api-https" = {
      priority                   = 300
      http_listener_name         = "https-api-listener"
      backend_address_pool_name  = "api-backend"
      backend_http_settings_name = "https-settings"
    }
  }

  rewrite_rule_sets = {
    "security-headers" = [
      {
        name          = "add-security-headers"
        rule_sequence = 100
        conditions    = []
        request_header_configurations = []
        response_header_configurations = [
          {
            header_name  = "Strict-Transport-Security"
            header_value = "max-age=31536000; includeSubDomains"
          },
          {
            header_name  = "X-Content-Type-Options"
            header_value = "nosniff"
          }
        ]
        url = null
      }
    ]
  }

  tags = {
    Environment = "production"
    CostCenter  = "IT"
  }
}
