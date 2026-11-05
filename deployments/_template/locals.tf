# Naming computed once, here, per CONVENTIONS.md #1 — modules take exact
# names as input, they don't derive them. Change the formula in exactly this
# one place if the naming convention ever needs to change.

locals {
  name_prefix        = "${var.customer_short_name}-${var.environment}-${var.location_code}-${format("%03d", var.instance_number)}"
  name_prefix_nodash = replace(local.name_prefix, "-", "") # storage account names allow no hyphens

  # ── Compute subscription ─────────────────────────────────────────────────────
  # Every workload resource goes in this resource group.
  resource_group_name = var.existing_compute_resource_group_name != "" ? var.existing_compute_resource_group_name : module.resource_groups[0].names["main"]

  # ── Landing Zone subscription ────────────────────────────────────────────────
  # The shared resource group exists whenever something in the landing zone needs it.
  landing_zone_enabled            = var.enable_hub_networking || var.enable_shared_key_vault || local.create_log_analytics || var.enable_front_door
  create_log_analytics            = var.enable_log_analytics && var.log_analytics_workspace_id == null
  shared_resource_group_name      = local.landing_zone_enabled ? module.shared_resource_groups[0].names["shared"] : null
  shared_resource_group_base_name = "rg-shared-${local.name_prefix}"
  # Key Vault names are capped at 24 characters, so the shared vault drops the
  # region and instance parts of the prefix.
  shared_key_vault_name = "kv-shared-${var.customer_short_name}-${var.environment}"

  # Prefer a caller-supplied shared workspace. Otherwise use the workspace
  # created in the landing zone when observability is enabled.
  log_analytics_workspace_id = var.log_analytics_workspace_id != null ? var.log_analytics_workspace_id : try(module.log_analytics[0].workspace_id, null)

  # Gate diagnostic-setting calls on this, not on the workspace ID: a workspace
  # created in the same run has an unknown ID at plan time, and an unknown
  # value cannot decide count/for_each.
  diagnostics_enabled = var.log_analytics_workspace_id != null || local.create_log_analytics

  default_tags = var.tags
}
