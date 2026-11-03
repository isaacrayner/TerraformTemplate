# Azure Cosmos DB Module

resource "azurerm_cosmosdb_account" "cosmos" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = var.kind

  automatic_failover_enabled        = var.enable_automatic_failover
  multiple_write_locations_enabled  = var.enable_multiple_write_locations
  free_tier_enabled                 = var.enable_free_tier
  public_network_access_enabled     = var.public_network_access_enabled
  is_virtual_network_filter_enabled = length(var.virtual_network_subnet_ids) > 0
  ip_range_filter                   = var.ip_range_filter

  network_acl_bypass_for_azure_services = var.network_acl_bypass_for_azure_services

  consistency_policy {
    consistency_level       = var.consistency_level
    max_interval_in_seconds = var.consistency_level == "BoundedStaleness" ? var.max_interval_in_seconds : null
    max_staleness_prefix    = var.consistency_level == "BoundedStaleness" ? var.max_staleness_prefix : null
  }

  dynamic "geo_location" {
    for_each = var.geo_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = geo_location.value.zone_redundant
    }
  }

  dynamic "capabilities" {
    for_each = var.capabilities
    content {
      name = capabilities.value
    }
  }

  dynamic "virtual_network_rule" {
    for_each = var.virtual_network_subnet_ids
    content {
      id                                   = virtual_network_rule.value
      ignore_missing_vnet_service_endpoint = false
    }
  }

  backup {
    type                = var.backup_type
    interval_in_minutes = var.backup_type == "Periodic" ? var.backup_interval_in_minutes : null
    retention_in_hours  = var.backup_type == "Periodic" ? var.backup_retention_in_hours : null
    storage_redundancy  = var.backup_type == "Periodic" ? var.backup_storage_redundancy : null
    tier                = var.backup_type == "Continuous" ? var.continuous_tier : null
  }

  lifecycle {
    precondition {
      condition     = length(var.geo_locations) > 0
      error_message = "At least one geo_location is required (the primary region, failover_priority = 0)."
    }

    precondition {
      condition     = var.consistency_level != "BoundedStaleness" || (var.max_interval_in_seconds != null && var.max_staleness_prefix != null)
      error_message = "max_interval_in_seconds and max_staleness_prefix are required when consistency_level is BoundedStaleness."
    }
  }

  tags = var.tags
}
