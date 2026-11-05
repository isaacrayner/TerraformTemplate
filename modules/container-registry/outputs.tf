output "id" {
  description = "Container Registry resource ID."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "Container Registry name."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Registry login server hostname."
  value       = azurerm_container_registry.this.login_server
}

output "principal_id" {
  description = "System-assigned managed identity principal ID."
  value       = azurerm_container_registry.this.identity[0].principal_id
}
