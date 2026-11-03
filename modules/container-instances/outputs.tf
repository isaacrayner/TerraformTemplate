# Output Values for Container Instances Module

output "container_group_id" {
  description = "Container group resource ID"
  value       = azurerm_container_group.aci.id
}

output "container_group_name" {
  description = "Container group name"
  value       = azurerm_container_group.aci.name
}

output "ip_address" {
  description = "Assigned IP address (public or private, depending on ip_address_type)"
  value       = azurerm_container_group.aci.ip_address
}

output "fqdn" {
  description = "Fully qualified domain name, only populated when dns_name_label is set"
  value       = azurerm_container_group.aci.fqdn
}

output "principal_id" {
  description = "Managed identity principal ID, or null when identity_type is unset"
  value       = try(azurerm_container_group.aci.identity[0].principal_id, null)
}
