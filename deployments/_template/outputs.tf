# Output Values for Deployment

# =====================================================
# SPOKE NETWORKING OUTPUTS (Compute subscription)
# =====================================================
output "vnet_id" {
  description = "Spoke Virtual Network ID"
  value       = var.enable_spoke_networking ? module.spoke_networking[0].vnet_id : null
}

output "vnet_name" {
  description = "Spoke Virtual Network name"
  value       = var.enable_spoke_networking ? module.spoke_networking[0].vnet_name : null
}

output "subnet_ids" {
  description = "Map of spoke subnet keys to their resource IDs"
  value       = var.enable_spoke_networking ? module.spoke_networking[0].subnet_ids : {}
}

output "resource_group_name" {
  description = "Resource group for this deployment's workloads (Compute subscription)"
  value       = local.resource_group_name
}

# =====================================================
# LANDING ZONE OUTPUTS (Landing Zone subscription)
# =====================================================
output "shared_resource_group_name" {
  description = "Shared resource group for hub networking, shared Key Vault, Log Analytics and Front Door"
  value       = local.shared_resource_group_name
}

output "hub_vnet_id" {
  description = "Hub Virtual Network ID"
  value       = var.enable_hub_networking ? module.hub_networking[0].vnet_id : null
}

output "hub_vnet_name" {
  description = "Hub Virtual Network name"
  value       = var.enable_hub_networking ? module.hub_networking[0].vnet_name : null
}

output "hub_subnet_ids" {
  description = "Map of hub subnet keys to their resource IDs"
  value       = var.enable_hub_networking ? module.hub_networking[0].subnet_ids : {}
}

output "shared_key_vault_uri" {
  description = "Shared Key Vault URI"
  value       = var.enable_shared_key_vault ? module.shared_key_vault[0].key_vault_uri : null
}

output "shared_key_vault_id" {
  description = "Shared Key Vault resource ID"
  value       = var.enable_shared_key_vault ? module.shared_key_vault[0].key_vault_id : null
}

# =====================================================
# MONITORING AND WORKLOAD OUTPUTS
# =====================================================
output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace (created in the landing zone, or supplied)."
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

# =====================================================
# AVD OUTPUTS (Compute subscription)
# =====================================================
output "avd_workspace_id" {
  description = "AVD Workspace resource ID"
  value       = var.enable_avd ? module.avd[0].workspace_id : null
}

output "avd_host_pool_ids" {
  description = "Map of AVD host pool keys to their resource IDs"
  value       = var.enable_avd ? module.avd[0].host_pool_ids : {}
}

output "avd_session_host_names" {
  description = "Map of session host keys to their VM names"
  value       = var.enable_avd ? module.avd[0].session_host_names : {}
}

# =====================================================
# ACA OUTPUTS (Compute subscription)
# =====================================================
output "aca_environment_id" {
  description = "Container App Environment resource ID"
  value       = var.enable_aca ? module.aca[0].environment_id : null
}

output "aca_container_app_urls" {
  description = "Map of container app keys to their FQDNs (ingress-enabled apps only)"
  value       = var.enable_aca ? module.aca[0].container_app_urls : {}
}

# =====================================================
# FRONT DOOR OUTPUTS (Landing Zone subscription)
# =====================================================
output "front_door_hostnames" {
  description = "Map of endpoint keys to their Front Door hostnames"
  value       = var.enable_front_door ? module.front_door[0].endpoint_hostnames : {}
}

output "front_door_waf_policy_id" {
  description = "WAF policy resource ID"
  value       = var.enable_front_door ? module.front_door[0].waf_policy_id : null
}

# Deployment Info
output "deployment_info" {
  description = "Summary of deployed resources"
  value = {
    customer    = var.customer_short_name
    environment = var.environment
    location    = var.location
    region_code = var.location_code
    subscriptions = {
      landing_zone = var.landing_zone_subscription_id
      compute      = var.compute_subscription_id
    }
    resource_counts = {
      hub_networking   = var.enable_hub_networking ? 1 : 0
      shared_key_vault = var.enable_shared_key_vault ? 1 : 0
      storage_accounts = length(var.storage_accounts)
      key_vaults       = length(var.key_vaults)
      # var.sql_databases is sensitive (it carries admin passwords) — a bare
      # length() of it taints this entire otherwise-harmless summary output.
      # nonsensitive() here is safe: only the count leaves this expression,
      # not any credential.
      sql_databases        = nonsensitive(length(var.sql_databases))
      spoke_networking     = var.enable_spoke_networking ? 1 : 0
      log_analytics        = local.diagnostics_enabled ? 1 : 0
      application_insights = length(var.application_insights)
      container_registries = length(var.container_registries)
      web_apps             = length(var.web_apps)
      function_apps        = length(var.function_apps)
      virtual_machines     = length(var.virtual_machines)
      front_doors          = var.enable_front_door ? 1 : 0
      avd_host_pools       = var.enable_avd ? nonsensitive(length(var.avd_host_pools)) : 0
    aca_container_apps = var.enable_aca ? length(var.container_apps) : 0 }
  }
}
