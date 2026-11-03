# Output Values for Storage Account Module

output "storage_account_id" {
  description = "Storage Account resource ID"
  value       = azurerm_storage_account.storage.id
}

output "storage_account_name" {
  description = "Storage Account name"
  value       = azurerm_storage_account.storage.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL"
  value       = azurerm_storage_account.storage.primary_blob_endpoint
}

output "primary_access_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.storage.primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string for the storage account"
  value       = azurerm_storage_account.storage.primary_connection_string
  sensitive   = true
}

output "blob_container_names" {
  description = "List of created blob container names"
  value       = [for c in azurerm_storage_container.containers : c.name]
}
