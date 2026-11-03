# Core Infrastructure
# Foundational resources that are (almost) always required.
# - Resource Group  : created here unless existing_resource_group_name is set
# - Networking      : VNet, Subnets, NSGs

# =====================================================
# RESOURCE GROUP (Core - skipped if existing_resource_group_name is set)
# =====================================================
module "resource_groups" {
  count  = var.existing_resource_group_name == "" ? 1 : 0
  source = "../../modules/resource-group"

  resource_groups = {
    main = {
      name     = "rg-${local.name_prefix}"
      location = var.location
    }
  }

  tags = var.tags
}

# =====================================================
# NETWORKING MODULE (Core - Always Required)
# =====================================================
module "networking" {
  count  = var.enable_networking ? 1 : 0
  source = "../../modules/networking"

  name                = "vnet-${local.name_prefix}"
  location            = var.location
  resource_group_name = local.resource_group_name

  vnet_address_space = var.vnet_address_space
  subnets            = var.subnets

  tags = var.tags
}

# =====================================================
# DIAGNOSTICS (created when this deployment creates a workspace or when the
# caller supplies a shared workspace ID; see CONVENTIONS.md #4.)
# =====================================================
module "diag_networking_nsg" {
  for_each = var.enable_networking && local.log_analytics_workspace_id != null ? module.networking[0].nsg_ids : {}
  source   = "../../modules/diagnostic-setting"

  name                       = "diag-${module.networking[0].nsg_names[each.key]}"
  target_resource_id         = each.value
  log_analytics_workspace_id = local.log_analytics_workspace_id
  metrics_enabled            = false # NSGs have no metrics
}
