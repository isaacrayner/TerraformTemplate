# Core Infrastructure — Compute subscription
# Foundational resources that are (almost) always required.
# - Resource Group  : created here unless existing_compute_resource_group_name is set
# - Spoke Networking: VNet, Subnets, NSGs; peered to the hub via hub-spoke-peering.tf

# =====================================================
# RESOURCE GROUP (Compute subscription; skipped if
# existing_compute_resource_group_name is set)
# =====================================================
module "resource_groups" {
  count     = var.existing_compute_resource_group_name == "" ? 1 : 0
  source    = "../../modules/resource-group"
  providers = { azurerm = azurerm.compute }

  resource_groups = {
    main = {
      name     = "rg-${local.name_prefix}"
      location = var.location
    }
  }

  tags = var.tags
}

# =====================================================
# SPOKE NETWORKING (Compute subscription)
# =====================================================
module "spoke_networking" {
  count     = var.enable_spoke_networking ? 1 : 0
  source    = "../../modules/networking"
  providers = { azurerm = azurerm.compute }

  name                = "vnet-spoke-${local.name_prefix}"
  location            = var.location
  resource_group_name = local.resource_group_name

  vnet_address_space = var.spoke_vnet_address_space
  subnets            = var.spoke_subnets

  tags = merge(var.tags, { NetworkTier = "Spoke" })
}

# =====================================================
# DIAGNOSTICS (created when this deployment creates a workspace or when the
# caller supplies a shared workspace ID; see CONVENTIONS.md #4.)
# =====================================================
module "diag_spoke_nsg" {
  for_each  = var.enable_spoke_networking && local.diagnostics_enabled ? module.spoke_networking[0].nsg_ids : {}
  source    = "../../modules/diagnostic-setting"
  providers = { azurerm = azurerm.compute }

  name                       = "diag-${module.spoke_networking[0].nsg_names[each.key]}"
  target_resource_id         = each.value
  log_analytics_workspace_id = local.log_analytics_workspace_id
  metrics_enabled            = false # NSGs have no metrics
}
