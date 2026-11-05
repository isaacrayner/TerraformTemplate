# Output Values for API Management Module

output "apim_id" {
  description = "API Management service resource ID"
  value       = azurerm_api_management.apim.id
}

output "apim_name" {
  description = "API Management service name"
  value       = azurerm_api_management.apim.name
}

output "gateway_url" {
  description = "API gateway URL"
  value       = azurerm_api_management.apim.gateway_url
}

output "portal_url" {
  description = "Publisher (legacy) portal URL"
  value       = azurerm_api_management.apim.portal_url
}

output "developer_portal_url" {
  description = "Developer portal URL"
  value       = azurerm_api_management.apim.developer_portal_url
}

output "management_api_url" {
  description = "Management API URL"
  value       = azurerm_api_management.apim.management_api_url
}

output "public_ip_addresses" {
  description = "Public IP addresses of the service"
  value       = azurerm_api_management.apim.public_ip_addresses
}

output "private_ip_addresses" {
  description = "Private IP addresses (VNet-integrated deployments only)"
  value       = azurerm_api_management.apim.private_ip_addresses
}

output "principal_id" {
  description = "Managed identity principal ID, or null when identity_type is unset"
  value       = try(azurerm_api_management.apim.identity[0].principal_id, null)
}
