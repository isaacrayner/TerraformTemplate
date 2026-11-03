# Output Values for SQL Database Module

output "sql_server_id" {
  description = "SQL Server resource ID"
  value       = azurerm_mssql_server.sql_server.id
}

output "sql_server_name" {
  description = "SQL Server name"
  value       = azurerm_mssql_server.sql_server.name
}

output "sql_server_fqdn" {
  description = "SQL Server fully qualified domain name"
  value       = azurerm_mssql_server.sql_server.fully_qualified_domain_name
}

output "database_id" {
  description = "SQL Database resource ID"
  value       = azurerm_mssql_database.database.id
}

output "database_name" {
  description = "SQL Database name"
  value       = azurerm_mssql_database.database.name
}

output "connection_string" {
  description = "SQL Server connection string"
  value       = "Server=tcp:${azurerm_mssql_server.sql_server.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.database.name};User ID=${var.admin_username};Password=${var.admin_password};Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;"
  sensitive   = true
}
