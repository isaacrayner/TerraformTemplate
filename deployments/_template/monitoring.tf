# Monitoring & Observability
#
# Log Analytics lives in the LANDING ZONE subscription (default provider), in
# the shared resource group, and receives diagnostics from both subscriptions
# (CONVENTIONS.md #4). Every diagnostic-setting call in this root gates on
# local.log_analytics_workspace_id (see locals.tf).
#
# Application Insights components are in applications.tf (Compute subscription)
# and are workspace-based on this workspace.

# =====================================================
# LOG ANALYTICS WORKSPACE (Landing Zone subscription)
# Skipped when log_analytics_workspace_id points at an existing workspace.
# =====================================================
module "log_analytics" {
  count  = local.create_log_analytics ? 1 : 0
  source = "../../modules/log-analytics"

  name                = "log-${local.name_prefix}"
  location            = var.location
  resource_group_name = local.shared_resource_group_name

  retention_in_days = var.log_analytics_retention_in_days
  daily_quota_gb    = var.log_analytics_daily_quota_gb

  tags = var.tags
}

# =====================================================
# MICROSOFT DEFENDER FOR CLOUD (Both subscriptions)
# Enable per-resource-type pricing via azurerm_security_center_subscription_pricing.
# Uncomment and extend for each resource type you want to protect.
# =====================================================
# resource "azurerm_security_center_subscription_pricing" "defender_vms_lz" {
#   # Default provider — Landing Zone subscription
#   tier          = "Standard"
#   resource_type = "VirtualMachines"
# }
#
# resource "azurerm_security_center_subscription_pricing" "defender_vms_compute" {
#   provider      = azurerm.compute
#   tier          = "Standard"
#   resource_type = "VirtualMachines"
# }
#
# resource "azurerm_security_center_subscription_pricing" "defender_appservices_compute" {
#   provider      = azurerm.compute
#   tier          = "Standard"
#   resource_type = "AppServices"
# }
#
# resource "azurerm_security_center_subscription_pricing" "defender_containers_compute" {
#   provider      = azurerm.compute
#   tier          = "Standard"
#   resource_type = "Containers"
# }
