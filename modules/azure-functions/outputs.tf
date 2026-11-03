output "id" {
  description = "Linux Function App resource ID."
  value       = azurerm_linux_function_app.this.id
}

output "name" {
  description = "Linux Function App name."
  value       = azurerm_linux_function_app.this.name
}

output "default_hostname" {
  description = "Default Azure hostname."
  value       = azurerm_linux_function_app.this.default_hostname
}

output "service_plan_id" {
  description = "Created or supplied plan ID."
  value       = local.service_plan_id
}

output "principal_id" {
  description = "Function app system-assigned managed identity principal ID."
  value       = azurerm_linux_function_app.this.identity[0].principal_id
}
