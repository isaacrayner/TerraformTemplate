resource "azurerm_container_registry" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  admin_enabled                 = var.admin_enabled
  anonymous_pull_enabled        = false
  public_network_access_enabled = var.public_network_access_enabled
  export_policy_enabled         = var.export_policy_enabled
  zone_redundancy_enabled       = var.zone_redundancy_enabled

  identity {
    type = "SystemAssigned"
  }

  dynamic "georeplications" {
    for_each = var.georeplications
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
      tags                    = merge(var.tags, georeplications.value.tags)
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.sku == "Premium" || (var.public_network_access_enabled && length(var.georeplications) == 0 && !var.zone_redundancy_enabled && var.export_policy_enabled)
      error_message = "Private access, geo-replication, zone redundancy, and disabled export policy require the Premium SKU."
    }
  }
}
