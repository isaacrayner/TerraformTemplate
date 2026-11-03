# Output Values for Cosmos DB Module

output "cosmosdb_account_id" {
  description = "Cosmos DB account resource ID"
  value       = azurerm_cosmosdb_account.cosmos.id
}

output "cosmosdb_account_name" {
  description = "Cosmos DB account name"
  value       = azurerm_cosmosdb_account.cosmos.name
}

output "endpoint" {
  description = "Account endpoint URL"
  value       = azurerm_cosmosdb_account.cosmos.endpoint
}

output "read_endpoints" {
  description = "Ordered list of read region endpoints"
  value       = azurerm_cosmosdb_account.cosmos.read_endpoints
}

output "write_endpoints" {
  description = "Ordered list of write region endpoints"
  value       = azurerm_cosmosdb_account.cosmos.write_endpoints
}

output "primary_key" {
  description = "Primary master key (SQL API)"
  value       = azurerm_cosmosdb_account.cosmos.primary_key
  sensitive   = true
}

output "primary_sql_connection_string" {
  description = "Primary SQL API connection string"
  value       = azurerm_cosmosdb_account.cosmos.primary_sql_connection_string
  sensitive   = true
}

output "primary_mongodb_connection_string" {
  description = "Primary MongoDB API connection string (only populated when kind = MongoDB)"
  value       = azurerm_cosmosdb_account.cosmos.primary_mongodb_connection_string
  sensitive   = true
}
