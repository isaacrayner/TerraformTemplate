# Output Values — Azure Container Apps Module

output "environment_id" {
  description = "Container App Environment resource ID"
  value       = azurerm_container_app_environment.env.id
}

output "environment_name" {
  description = "Container App Environment name"
  value       = azurerm_container_app_environment.env.name
}

output "environment_default_domain" {
  description = "Default domain of the Container App Environment (use for internal DNS)"
  value       = azurerm_container_app_environment.env.default_domain
}

output "environment_static_ip" {
  description = "Static IP of the Container App Environment (for DNS A-record when using internal LB)"
  value       = azurerm_container_app_environment.env.static_ip_address
}

output "container_app_ids" {
  description = "Map of container app keys to their resource IDs"
  value       = { for k, v in azurerm_container_app.apps : k => v.id }
}

output "container_app_urls" {
  description = "Map of container app keys to their latest revision FQDN (only for apps with ingress enabled)"
  value = {
    for k, v in azurerm_container_app.apps : k => v.latest_revision_fqdn
    if v.latest_revision_fqdn != ""
  }
}

output "container_app_outbound_ips" {
  description = "Map of container app keys to their outbound IP addresses"
  value       = { for k, v in azurerm_container_app.apps : k => v.outbound_ip_addresses }
}

output "container_app_principal_ids" {
  description = "Map of container app keys to their SystemAssigned managed identity principal IDs (for additional RBAC)"
  value       = { for k, v in azurerm_container_app.apps : k => v.identity[0].principal_id }
}
