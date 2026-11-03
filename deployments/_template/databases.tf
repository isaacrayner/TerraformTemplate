# Databases — Compute subscription
# Multiple SQL Servers and Databases for different applications/microservices
# Each key becomes part of the SQL Server name suffix

# =====================================================
# SQL DATABASES (Multiple Named Instances)
# =====================================================
module "sql_database" {
  # var.sql_databases is sensitive (admin passwords) — for_each can't take an
  # expression carrying the sensitive mark (same gotcha RADical hit and
  # documented as D55). nonsensitive() here only affects which keys Terraform
  # is allowed to iterate; each.value.admin_password stays exactly as
  # sensitive as var.sql_databases was.
  for_each  = nonsensitive(var.sql_databases)
  source    = "../../modules/sql-database"
  providers = { azurerm = azurerm.compute }

  name                = "sql-${local.name_prefix}-${each.key}"
  location            = var.location
  resource_group_name = local.resource_group_name

  admin_username = each.value.admin_username
  admin_password = each.value.admin_password
  database_name  = each.value.database_name
  sku_name       = each.value.sku_name
  max_size_gb    = each.value.max_size_gb
  zone_redundant = coalesce(each.value.zone_redundant, false)

  public_network_access_enabled = coalesce(each.value.public_network_access_enabled, false)

  tags = merge(var.tags, {
    Purpose = each.key # Tag with the purpose/application name
  })
}

module "diag_sql_server" {
  for_each  = local.diagnostics_enabled ? nonsensitive(var.sql_databases) : {}
  source    = "../../modules/diagnostic-setting"
  providers = { azurerm = azurerm.compute }

  name                       = "diag-${module.sql_database[each.key].sql_server_name}"
  target_resource_id         = module.sql_database[each.key].sql_server_id
  log_analytics_workspace_id = local.log_analytics_workspace_id
}

# =====================================================
# COSMOS DB, REDIS, AKS, API MANAGEMENT, CONTAINER INSTANCES
# =====================================================
# Stage 3's modules (cosmos-db, redis-cache, aks, api-management,
# container-instances — all implemented, see IMPLEMENTATION_ROADMAP.md) are
# deliberately NOT wired into this template as root variables/flags. Unlike
# Stage 2's modules, each of these needs workload-specific decisions
# (geo_locations, node pool shapes, VNet integration mode) that don't reduce
# to a generic map-of-objects the way storage_accounts/sql_databases do
# without either hiding real config choices or ballooning this root's
# variables.tf. Call them directly from a customer root instead — see each
# module's own README for a full usage example, e.g.:
#
# module "cosmos_db" {
#   source = "../../modules/cosmos-db"
#   providers = { azurerm = azurerm.compute }
#
#   name                 = "cosmos-${local.name_prefix}-sessions"
#   location             = var.location
#   resource_group_name  = local.resource_group_name
#
#   geo_locations = [
#     { location = var.location, failover_priority = 0 }
#   ]
#
#   tags = merge(var.tags, { Purpose = "sessions" })
# }
