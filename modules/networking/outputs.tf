# Output Values for Networking Module

output "vnet_id" {
  description = "Virtual Network resource ID"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_address_space" {
  description = "Address space of the Virtual Network"
  value       = azurerm_virtual_network.vnet.address_space
}

output "subnet_ids" {
  description = "Map of subnet keys to their resource IDs"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "subnet_names" {
  description = "Map of subnet keys to their full names"
  value       = { for k, v in azurerm_subnet.subnets : k => v.name }
}

output "nsg_ids" {
  description = "Map of NSG keys to their resource IDs"
  value       = { for k, v in azurerm_network_security_group.nsg : k => v.id }
}

output "nsg_names" {
  description = "Map of NSG keys to their full names"
  value       = { for k, v in azurerm_network_security_group.nsg : k => v.name }
}
