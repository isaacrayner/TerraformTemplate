# Azure SQL Database Module

# SQL Server
resource "azurerm_mssql_server" "sql_server" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.sql_version
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password

  minimum_tls_version           = "1.2"
  public_network_access_enabled = var.public_network_access_enabled

  # Emit the block only when configured. A static block with null required
  # fields passes schema validation but fails when Azure receives the request.
  dynamic "azuread_administrator" {
    for_each = var.enable_azure_ad_admin ? [1] : []
    content {
      login_username              = var.azure_ad_admin_login
      object_id                   = var.azure_ad_admin_object_id
      azuread_authentication_only = var.azure_ad_only_auth
    }
  }

  lifecycle {
    precondition {
      condition     = !var.enable_azure_ad_admin || (var.azure_ad_admin_login != null && var.azure_ad_admin_object_id != null)
      error_message = "azure_ad_admin_login and azure_ad_admin_object_id are required when enable_azure_ad_admin is true."
    }

    precondition {
      condition     = !var.azure_ad_only_auth || var.enable_azure_ad_admin
      error_message = "enable_azure_ad_admin must be true when azure_ad_only_auth is true."
    }
  }

  tags = var.tags
}

# SQL Database
resource "azurerm_mssql_database" "database" {
  name           = var.database_name
  server_id      = azurerm_mssql_server.sql_server.id
  collation      = var.collation
  sku_name       = var.sku_name
  max_size_gb    = var.max_size_gb
  zone_redundant = var.zone_redundant

  # Threat detection
  threat_detection_policy {
    state                = var.enable_advanced_threat_protection ? "Enabled" : "Disabled"
    email_account_admins = var.threat_detection_email_admins ? "Enabled" : "Disabled"
    email_addresses      = var.threat_detection_emails
    retention_days       = var.threat_detection_retention_days
  }

  tags = var.tags
}

# Firewall Rules — only meaningful when the server has a public endpoint at all
resource "azurerm_mssql_firewall_rule" "firewall_rules" {
  for_each = var.public_network_access_enabled ? { for rule in var.allowed_ip_ranges : rule.name => rule } : {}

  name             = each.value.name
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

# Allow Azure Services
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  count = var.public_network_access_enabled && var.allow_azure_services ? 1 : 0

  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Auditing
resource "azurerm_mssql_server_extended_auditing_policy" "audit" {
  count = var.enable_auditing ? 1 : 0

  server_id              = azurerm_mssql_server.sql_server.id
  storage_endpoint       = var.audit_storage_endpoint
  retention_in_days      = var.audit_retention_days
  log_monitoring_enabled = true

  lifecycle {
    precondition {
      condition     = var.audit_storage_endpoint != null
      error_message = "audit_storage_endpoint is required when enable_auditing is true."
    }
  }
}
