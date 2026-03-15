resource "azurerm_resource_group" "test" {
  name     = "rg-appgw-test"
  location = "eastus2"
}

resource "azurerm_virtual_network" "test" {
  name                = "vnet-appgw-test"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
}

resource "azurerm_subnet" "test" {
  name                 = "snet-appgw-test"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.2.0.0/24"]
}

resource "azurerm_public_ip" "test" {
  name                = "pip-appgw-test"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

module "test" {
  source = "../"

  name                = "appgw-test"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  subnet_id           = azurerm_subnet.test.id
  public_ip_id        = azurerm_public_ip.test.id

  sku_tier     = "WAF_v2"
  waf_enabled  = true
  waf_mode     = "Prevention"

  backend_address_pools = {
    default = {
      ip_addresses = ["10.2.1.10", "10.2.1.11"]
    }
  }

  backend_http_settings = {
    default = {
      port     = 80
      protocol = "Http"
    }
  }

  http_listeners = {
    http = {
      frontend_port_name = "http"
      protocol           = "Http"
    }
  }

  request_routing_rules = {
    http = {
      priority                   = 100
      http_listener_name         = "http"
      backend_address_pool_name  = "default"
      backend_http_settings_name = "default"
    }
  }

  tags = {
    Environment = "test"
    ManagedBy   = "terraform"
  }
}
