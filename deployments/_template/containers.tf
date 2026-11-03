# Container registries — Compute subscription.
#
# Container image registries. Workload-to-registry role assignments are kept in
# this root because authorization joins two independently reusable modules.

module "container_registry" {
  for_each  = var.container_registries
  source    = "../../modules/container-registry"
  providers = { azurerm = azurerm.compute }

  name                = "acr${local.name_prefix_nodash}${each.key}"
  location            = var.location
  resource_group_name = local.resource_group_name

  sku                           = each.value.sku
  public_network_access_enabled = each.value.public_network_access_enabled
  export_policy_enabled         = each.value.export_policy_enabled
  zone_redundancy_enabled       = each.value.zone_redundancy_enabled
  georeplications               = each.value.georeplications

  tags = merge(var.tags, { Purpose = each.key })
}

module "diag_container_registry" {
  for_each  = local.diagnostics_enabled ? var.container_registries : {}
  source    = "../../modules/diagnostic-setting"
  providers = { azurerm = azurerm.compute }

  name                       = "diag-${module.container_registry[each.key].name}"
  target_resource_id         = module.container_registry[each.key].id
  log_analytics_workspace_id = local.log_analytics_workspace_id
}

locals {
  web_app_registry_bindings = {
    for key, app in var.web_apps : key => app
    if app.container_registry_key != null
  }
}

resource "azurerm_role_assignment" "web_app_acr_pull" {
  for_each = local.web_app_registry_bindings
  provider = azurerm.compute

  scope                = module.container_registry[each.value.container_registry_key].id
  role_definition_name = "AcrPull"
  principal_id         = module.web_app[each.key].principal_id
}
