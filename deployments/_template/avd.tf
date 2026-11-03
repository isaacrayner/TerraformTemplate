# Azure Virtual Desktop — Compute subscription
# Host pools, session hosts and a shared workspace. Supports large deployments:
# multiple pools with different VM SKUs per pool.
#
# TO ENABLE:
#   1. enable_spoke_networking = true
#   2. Add AVD subnets in var.spoke_subnets (see terraform.tfvars.example)
#   3. Set enable_avd = true and avd_host_pools in terraform.tfvars

module "avd" {
  count     = var.enable_avd ? 1 : 0
  source    = "../../modules/azure-virtual-desktop"
  providers = { azurerm = azurerm.compute }

  name_suffix         = local.name_prefix
  location            = var.location
  resource_group_name = local.resource_group_name

  workspace_friendly_name = var.avd_workspace_friendly_name
  workspace_description   = var.avd_workspace_description

  # Build the module's host_pools from var.avd_host_pools, resolving subnet_key → subnet_id.
  # The guard prevents evaluating module.spoke_networking[0] when spoke networking is disabled.
  host_pools = var.enable_spoke_networking ? {
    for pool_key, pool in var.avd_host_pools : pool_key => {
      type                  = pool.type
      load_balancer_type    = pool.load_balancer_type
      max_sessions_per_host = pool.max_sessions_per_host
      app_group_type        = pool.app_group_type
      start_vm_on_connect   = pool.start_vm_on_connect
      friendly_name         = pool.friendly_name
      session_host_count    = pool.session_host_count
      vm_size               = pool.vm_size
      vm_name_prefix        = pool.vm_name_prefix
      subnet_id             = module.spoke_networking[0].subnet_ids[pool.subnet_key]
      os_disk_type          = pool.os_disk_type
      source_image_id       = pool.source_image_id # null = use the marketplace image below
      image_publisher       = pool.image_publisher
      image_offer           = pool.image_offer
      image_sku             = pool.image_sku
      aad_joined            = pool.aad_joined
      intune_enrollment     = pool.intune_enrollment
      admin_username        = pool.admin_username
      admin_password        = pool.admin_password
      enable_scaling_plan   = pool.enable_scaling_plan
      license_type          = pool.license_type
    }
  } : {}

  scaling_plan_timezone        = var.avd_scaling_plan_timezone
  scaling_plan_peak_start_time = var.avd_scaling_plan_peak_start_time
  scaling_plan_peak_end_time   = var.avd_scaling_plan_peak_end_time

  tags = var.tags
}

# Diagnostics for the AVD control plane (CONVENTIONS.md #4)
locals {
  avd_diagnostic_targets = var.enable_avd && local.diagnostics_enabled ? merge(
    { workspace = module.avd[0].workspace_id },
    { for k, id in module.avd[0].host_pool_ids : "pool-${k}" => id },
    { for k, id in module.avd[0].application_group_ids : "ag-${k}" => id },
  ) : {}
}

module "diag_avd" {
  for_each  = toset(keys(local.avd_diagnostic_targets))
  source    = "../../modules/diagnostic-setting"
  providers = { azurerm = azurerm.compute }

  name                       = "diag-avd-${each.key}-${local.name_prefix}"
  target_resource_id         = local.avd_diagnostic_targets[each.key]
  log_analytics_workspace_id = local.log_analytics_workspace_id
  metrics_enabled            = false # AVD control-plane resources emit logs only
}
