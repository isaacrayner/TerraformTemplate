# Key Vault Module

resource "azurerm_key_vault" "kv" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = var.sku_name

  # Security best practices
  enable_rbac_authorization       = var.enable_rbac_authorization
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment

  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled

  public_network_access_enabled = var.network_access.public_network_access_enabled

  # azurerm_key_vault's network_acls.bypass is a single string ("AzureServices"
  # or "None"), unlike Storage Account's set(string) — take the first entry of
  # the shared network_access.bypass list.
  network_acls {
    bypass                     = length(var.network_access.bypass) > 0 ? var.network_access.bypass[0] : "None"
    default_action             = var.network_access.default_action
    ip_rules                   = var.network_access.ip_rules
    virtual_network_subnet_ids = var.network_access.subnet_ids
  }

  tags = var.tags
}
