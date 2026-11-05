output "id" {
  description = "Linux VM resource ID."
  value       = azurerm_linux_virtual_machine.this.id
}

output "name" {
  description = "Linux VM name."
  value       = azurerm_linux_virtual_machine.this.name
}

output "virtual_machine_id" {
  description = "Azure VM UUID."
  value       = azurerm_linux_virtual_machine.this.virtual_machine_id
}

output "network_interface_id" {
  description = "Primary NIC resource ID."
  value       = azurerm_network_interface.this.id
}

output "private_ip_address" {
  description = "Primary private IP address."
  value       = azurerm_network_interface.this.private_ip_address
}

output "principal_id" {
  description = "VM system-assigned managed identity principal ID."
  value       = azurerm_linux_virtual_machine.this.identity[0].principal_id
}
