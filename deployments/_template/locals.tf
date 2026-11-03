# Naming computed once, here, per CONVENTIONS.md #1 — modules take exact
# names as input, they don't derive them. Change the formula in exactly this
# one place if the naming convention ever needs to change.

locals {
  name_prefix        = "${var.customer_short_name}-${var.environment}-${var.location_code}-${format("%03d", var.instance_number)}"
  name_prefix_nodash = replace(local.name_prefix, "-", "") # storage account names allow no hyphens

  resource_group_name = var.existing_resource_group_name != "" ? var.existing_resource_group_name : module.resource_groups[0].names["main"]

  # Prefer a caller-supplied shared workspace. Otherwise use the workspace
  # created by this deployment when observability is enabled.
  log_analytics_workspace_id = var.log_analytics_workspace_id != null ? var.log_analytics_workspace_id : try(module.log_analytics[0].workspace_id, null)

  default_tags = var.tags
}
