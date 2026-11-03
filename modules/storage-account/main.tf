# Storage Account Module

resource "azurerm_storage_account" "storage" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

  # Security best practices
  https_traffic_only_enabled        = var.enable_https_only
  min_tls_version                   = var.min_tls_version
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = var.network_access.public_network_access_enabled

  network_rules {
    default_action             = var.network_access.default_action
    bypass                     = var.network_access.bypass
    ip_rules                   = var.network_access.ip_rules
    virtual_network_subnet_ids = var.network_access.subnet_ids
  }

  # Enable blob versioning for data protection
  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.blob_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.container_delete_retention_days
    }
  }

  tags = var.tags
}

# Optional Blob Containers
resource "azurerm_storage_container" "containers" {
  for_each = toset(var.blob_containers)

  name                  = each.value
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}
