# Key Vaults
# Multiple named instances for different purposes/applications
# Each key becomes part of the Key Vault name suffix

# =====================================================
# KEY VAULTS (Multiple Named Instances)
# =====================================================
module "key_vault" {
  for_each = var.key_vaults
  source   = "../../modules/key-vault"

  name                = "kv-${local.name_prefix}-${each.key}"
  location            = var.location
  resource_group_name = local.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name                    = each.value.sku_name
  enable_rbac_authorization   = each.value.enable_rbac
  enabled_for_disk_encryption = true

  network_access = each.value.network_access

  tags = merge(var.tags, {
    Purpose = each.key # Tag with the purpose/application name
  })
}

module "diag_key_vault" {
  for_each = local.log_analytics_workspace_id != null ? var.key_vaults : {}
  source   = "../../modules/diagnostic-setting"

  name                       = "diag-${module.key_vault[each.key].key_vault_name}"
  target_resource_id         = module.key_vault[each.key].key_vault_id
  log_analytics_workspace_id = local.log_analytics_workspace_id
}
