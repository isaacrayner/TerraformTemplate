# Output Values — Azure Front Door + WAF Module

output "profile_id" {
  description = "Front Door Profile resource ID"
  value       = azurerm_cdn_frontdoor_profile.profile.id
}

output "profile_name" {
  description = "Front Door Profile name"
  value       = azurerm_cdn_frontdoor_profile.profile.name
}

output "endpoint_hostnames" {
  description = "Map of endpoint keys to their generated hostnames (e.g., fde-contoso-prod-001-default.z01.azurefd.net)"
  value       = { for k, v in azurerm_cdn_frontdoor_endpoint.endpoints : k => v.host_name }
}

output "endpoint_ids" {
  description = "Map of endpoint keys to their resource IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_endpoint.endpoints : k => v.id }
}

output "origin_group_ids" {
  description = "Map of origin group keys to their resource IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_origin_group.groups : k => v.id }
}

output "route_ids" {
  description = "Map of route keys to their resource IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_route.routes : k => v.id }
}

output "waf_policy_id" {
  description = "WAF policy resource ID (null when enable_waf = false)"
  value       = var.enable_waf ? azurerm_cdn_frontdoor_firewall_policy.waf[0].id : null
}

output "waf_policy_name" {
  description = "WAF policy name (null when enable_waf = false)"
  value       = var.enable_waf ? azurerm_cdn_frontdoor_firewall_policy.waf[0].name : null
}
