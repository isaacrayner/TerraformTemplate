# Azure Container Apps — Compute subscription
# One Container App Environment with the apps in var.container_apps.
# Logs go to the shared Log Analytics workspace (CONVENTIONS.md #4).
#
# TO ENABLE:
#   1. Set enable_aca = true and container_apps in terraform.tfvars
#   2. For a private environment: add an "aca" subnet to var.spoke_subnets with
#      delegation = { name = "aca-delegation", service = "Microsoft.App/environments" }
#      and set aca_internal_load_balancer = true
#   3. To pull private images: add a registry to var.container_registries and set
#      aca_container_registry_key to its key

module "aca" {
  count     = var.enable_aca ? 1 : 0
  source    = "../../modules/azure-container-apps"
  providers = { azurerm = azurerm.compute }

  name_suffix                = local.name_prefix
  location                   = var.location
  resource_group_name        = local.resource_group_name
  log_analytics_workspace_id = local.log_analytics_workspace_id

  # VNet integration when an "aca" subnet exists; otherwise a public environment.
  infrastructure_subnet_id       = var.enable_spoke_networking ? lookup(module.spoke_networking[0].subnet_ids, "aca", null) : null
  internal_load_balancer_enabled = var.aca_internal_load_balancer

  container_registry = var.aca_container_registry_key == null ? null : {
    id           = module.container_registry[var.aca_container_registry_key].id
    login_server = module.container_registry[var.aca_container_registry_key].login_server
  }

  container_apps = var.container_apps

  tags = var.tags
}
