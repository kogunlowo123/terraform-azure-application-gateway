locals {
  frontend_ip_configuration_name = "appgw-frontend-ip"
  gateway_ip_configuration_name  = "appgw-gateway-ip"

  sku_name = var.sku_tier

  waf_configuration = var.waf_enabled ? {
    enabled          = true
    firewall_mode    = var.waf_mode
    rule_set_version = var.waf_rule_set_version
  } : null

  default_tags = merge(var.tags, {
    ManagedBy = "Terraform"
    Module    = "terraform-azure-application-gateway"
  })
}
