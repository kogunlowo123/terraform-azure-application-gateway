provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-appgw-basic"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-appgw"
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
  name                = "pip-appgw"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

module "application_gateway" {
  source = "../../"

  name                = "appgw-basic"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  subnet_id           = azurerm_subnet.appgw.id
  public_ip_id        = azurerm_public_ip.example.id

  backend_address_pools = {
    "default" = {
      ip_addresses = ["10.0.2.4", "10.0.2.5"]
    }
  }

  backend_http_settings = {
    "default" = {
      port     = 80
      protocol = "Http"
    }
  }

  http_listeners = {
    "http" = {
      frontend_port_name = "http"
      protocol           = "Http"
    }
  }

  request_routing_rules = {
    "http-rule" = {
      priority                   = 100
      http_listener_name         = "http"
      backend_address_pool_name  = "default"
      backend_http_settings_name = "default"
    }
  }

  tags = {
    Environment = "dev"
  }
}
