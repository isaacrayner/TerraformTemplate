output "id" {
  description = "Application Insights resource ID."
  value       = azurerm_application_insights.this.id
}

output "name" {
  description = "Application Insights component name."
  value       = azurerm_application_insights.this.name
}

output "app_id" {
  description = "Application ID used by the Application Insights API."
  value       = azurerm_application_insights.this.app_id
}

output "connection_string" {
  description = "Connection string for application telemetry configuration."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "instrumentation_key" {
  description = "Legacy instrumentation key. Prefer connection_string."
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}
