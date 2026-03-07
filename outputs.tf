output "application_gateway_id" {
  description = "The ID of the Application Gateway."
  value       = azurerm_application_gateway.this.id
}

output "application_gateway_name" {
  description = "The name of the Application Gateway."
  value       = azurerm_application_gateway.this.name
}

output "waf_policy_id" {
  description = "The ID of the WAF policy."
  value       = var.waf_enabled ? azurerm_web_application_firewall_policy.this[0].id : null
}

output "backend_address_pool_ids" {
  description = "Map of backend address pool names to IDs."
  value = {
    for pool in azurerm_application_gateway.this.backend_address_pool : pool.name => pool.id
  }
}

output "frontend_ip_configuration_ids" {
  description = "Map of frontend IP configuration names to IDs."
  value = {
    for fe in azurerm_application_gateway.this.frontend_ip_configuration : fe.name => fe.id
  }
}

output "http_listener_ids" {
  description = "Map of HTTP listener names to IDs."
  value = {
    for listener in azurerm_application_gateway.this.http_listener : listener.name => listener.id
  }
}
