output "id" {
  description = "Linux Web App resource ID."
  value       = azurerm_linux_web_app.this.id
}

output "name" {
  description = "Linux Web App name."
  value       = azurerm_linux_web_app.this.name
}

output "default_hostname" {
  description = "Default Azure hostname."
  value       = azurerm_linux_web_app.this.default_hostname
}

output "service_plan_id" {
  description = "Created or supplied App Service Plan ID."
  value       = local.service_plan_id
}

output "principal_id" {
  description = "Web app system-assigned managed identity principal ID."
  value       = azurerm_linux_web_app.this.identity[0].principal_id
}
