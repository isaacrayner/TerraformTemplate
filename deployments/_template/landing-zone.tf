# Landing Zone Resources
# All resources here deploy to the LANDING ZONE subscription (default provider, no alias).
#
# Contains:
#   - Shared Resource Group   — hosts every landing-zone resource below
#   - Hub Virtual Network     — peered to the spoke in the Compute subscription
#   - Shared Key Vault        — platform secrets (AVD creds, certs, SP secrets)
#   - Log Analytics Workspace — centralised logs from both subscriptions (monitoring.tf)
#   - Front Door + WAF        — global HTTP/S entry point (front-door.tf)

# =====================================================
# SHARED RESOURCE GROUP (Landing Zone subscription)
# =====================================================
module "shared_resource_groups" {
  count  = local.landing_zone_enabled ? 1 : 0
  source = "../../modules/resource-group"

  resource_groups = {
    shared = {
      name     = local.shared_resource_group_base_name
      location = var.location
    }
  }

  tags = var.tags
}

# =====================================================
# HUB NETWORKING (Landing Zone subscription)
# Same networking module as the spoke, but:
#   - Different address space (e.g. 10.100.0.0/16)
#   - GatewaySubnet / AzureFirewallSubnet skip NSG attachment automatically
#   - Peered to the spoke via hub-spoke-peering.tf
# =====================================================
module "hub_networking" {
  count  = var.enable_hub_networking ? 1 : 0
  source = "../../modules/networking"

  name                = "vnet-hub-${local.name_prefix}"
  location            = var.location
  resource_group_name = local.shared_resource_group_name

  vnet_address_space = var.hub_vnet_address_space
  subnets            = var.hub_subnets

  tags = merge(var.tags, { NetworkTier = "Hub" })
}

module "diag_hub_nsg" {
  for_each = var.enable_hub_networking && local.diagnostics_enabled ? module.hub_networking[0].nsg_ids : {}
  source   = "../../modules/diagnostic-setting"

  name                       = "diag-${module.hub_networking[0].nsg_names[each.key]}"
  target_resource_id         = each.value
  log_analytics_workspace_id = local.log_analytics_workspace_id
  metrics_enabled            = false # NSGs have no metrics
}

# =====================================================
# SHARED KEY VAULT (Landing Zone subscription)
# Stores platform-level secrets only — AVD domain-join credentials,
# shared service principal secrets, wildcard certificates.
# Customer-application secrets belong in the Key Vaults in the
# Compute subscription (key-vaults.tf).
# =====================================================
module "shared_key_vault" {
  count  = var.enable_shared_key_vault ? 1 : 0
  source = "../../modules/key-vault"

  name                = local.shared_key_vault_name
  location            = var.location
  resource_group_name = local.shared_resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name                  = "standard"
  enable_rbac_authorization = true

  tags = merge(var.tags, { Purpose = "shared-platform-secrets" })
}

module "diag_shared_key_vault" {
  count  = var.enable_shared_key_vault && local.diagnostics_enabled ? 1 : 0
  source = "../../modules/diagnostic-setting"

  name                       = "diag-${module.shared_key_vault[0].key_vault_name}"
  target_resource_id         = module.shared_key_vault[0].key_vault_id
  log_analytics_workspace_id = local.log_analytics_workspace_id
}
