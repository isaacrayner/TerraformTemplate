# Output Values for Deployment

# Networking Outputs
output "vnet_id" {
  description = "Virtual Network ID"
  value       = var.enable_networking ? module.networking[0].vnet_id : null
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = var.enable_networking ? module.networking[0].vnet_name : null
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = var.enable_networking ? module.networking[0].subnet_ids : {}
}

output "resource_group_name" {
  description = "Resource group name for this deployment"
  value       = local.resource_group_name
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the created or supplied Log Analytics workspace."
  value       = local.log_analytics_workspace_id
}

output "application_insights" {
  description = "Application Insights resource IDs and app IDs by workload key."
  value = {
    for key, component in module.application_insights : key => {
      id     = component.id
      app_id = component.app_id
    }
  }
}

output "container_registries" {
  description = "Container Registry IDs and login servers by key."
  value = {
    for key, registry in module.container_registry : key => {
      id           = registry.id
      login_server = registry.login_server
    }
  }
}

output "web_apps" {
  description = "Linux Web App IDs, hostnames, and managed identity principal IDs by key."
  value = {
    for key, app in module.web_app : key => {
      id               = app.id
      default_hostname = app.default_hostname
      principal_id     = app.principal_id
    }
  }
}

output "function_apps" {
  description = "Linux Function App IDs, hostnames, and managed identity principal IDs by key."
  value = {
    for key, app in module.function_app : key => {
      id               = app.id
      default_hostname = app.default_hostname
      principal_id     = app.principal_id
    }
  }
}

output "virtual_machines" {
  description = "Linux VM IDs, private IPs, and managed identity principal IDs by key."
  value = {
    for key, vm in module.virtual_machine : key => {
      id                 = vm.id
      private_ip_address = vm.private_ip_address
      principal_id       = vm.principal_id
    }
  }
}

# Storage Account Outputs (Multiple Instances)
output "storage_accounts" {
  description = "Map of storage account names and their details"
  value = {
    for key, sa in module.storage_account : key => {
      name          = sa.storage_account_name
      id            = sa.storage_account_id
      blob_endpoint = sa.primary_blob_endpoint
      purpose       = key
    }
  }
}

# Key Vault Outputs (Multiple Instances)
output "key_vaults" {
  description = "Map of Key Vault names and their details"
  value = {
    for key, kv in module.key_vault : key => {
      name    = kv.key_vault_name
      id      = kv.key_vault_id
      uri     = kv.key_vault_uri
      purpose = key
    }
  }
}

# SQL Database Outputs (Multiple Instances)
output "sql_databases" {
  description = "Map of SQL Server names and their details"
  value = {
    for key, sql in module.sql_database : key => {
      server_name   = sql.sql_server_name
      server_fqdn   = sql.sql_server_fqdn
      database_name = sql.database_name
      database_id   = sql.database_id
      purpose       = key
    }
  }
  sensitive = true # Contains sensitive server info
}

# Deployment Info
output "deployment_info" {
  description = "Summary of deployed resources"
  value = {
    customer    = var.customer_short_name
    environment = var.environment
    location    = var.location
    region_code = var.location_code
    resource_counts = {
      storage_accounts = length(var.storage_accounts)
      key_vaults       = length(var.key_vaults)
      # var.sql_databases is sensitive (it carries admin passwords) — a bare
      # length() of it taints this entire otherwise-harmless summary output.
      # nonsensitive() here is safe: only the count leaves this expression,
      # not any credential.
      sql_databases        = nonsensitive(length(var.sql_databases))
      networking           = var.enable_networking ? 1 : 0
      log_analytics        = local.log_analytics_workspace_id != null ? 1 : 0
      application_insights = length(var.application_insights)
      container_registries = length(var.container_registries)
      web_apps             = length(var.web_apps)
      function_apps        = length(var.function_apps)
      virtual_machines     = length(var.virtual_machines)
    }
  }
}
