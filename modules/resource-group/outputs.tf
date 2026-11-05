output "ids" {
  description = "Map of logical name => resource group ID."
  value       = { for k, rg in azurerm_resource_group.this : k => rg.id }
}

output "names" {
  description = "Map of logical name => resource group name."
  value       = { for k, rg in azurerm_resource_group.this : k => rg.name }
}
