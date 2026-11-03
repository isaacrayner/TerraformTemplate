# Storage Accounts
# Multiple named instances for different purposes/applications
# Each key becomes part of the storage account name suffix

# =====================================================
# STORAGE ACCOUNTS (Multiple Named Instances)
# =====================================================
module "storage_account" {
  for_each = var.storage_accounts
  source   = "../../modules/storage-account"

  name                = "st${local.name_prefix_nodash}${each.key}"
  location            = var.location
  resource_group_name = local.resource_group_name

  account_tier             = each.value.tier
  account_replication_type = each.value.replication_type
  blob_containers          = each.value.blob_containers

  network_access = each.value.network_access

  tags = merge(var.tags, {
    Purpose = each.key # Tag with the purpose/application name
  })
}

module "diag_storage_account" {
  for_each = local.log_analytics_workspace_id != null ? var.storage_accounts : {}
  source   = "../../modules/diagnostic-setting"

  name                       = "diag-${module.storage_account[each.key].storage_account_name}"
  target_resource_id         = module.storage_account[each.key].storage_account_id
  log_analytics_workspace_id = local.log_analytics_workspace_id
}
