# Application telemetry, Linux Web Apps, and Linux Function Apps.

module "application_insights" {
  for_each = var.application_insights
  source   = "../../modules/application-insights"

  name                = "appi-${each.key}-${local.name_prefix}"
  location            = var.location
  resource_group_name = local.resource_group_name
  workspace_id        = local.log_analytics_workspace_id

  application_type     = each.value.application_type
  daily_data_cap_in_gb = each.value.daily_data_cap_in_gb
  retention_in_days    = each.value.retention_in_days
  sampling_percentage  = each.value.sampling_percentage

  tags = merge(var.tags, { Purpose = each.key })
}

module "web_app" {
  for_each = var.web_apps
  source   = "../../modules/app-service"

  name                = "app-${each.key}-${local.name_prefix}"
  service_plan_name   = "asp-${each.key}-${local.name_prefix}"
  location            = var.location
  resource_group_name = local.resource_group_name

  service_plan_sku_name                   = each.value.service_plan_sku_name
  public_network_access_enabled           = each.value.public_network_access_enabled
  virtual_network_subnet_id               = each.value.vnet_integration_subnet_key == null ? null : module.networking[0].subnet_ids[each.value.vnet_integration_subnet_key]
  health_check_path                       = each.value.health_check_path
  application_stack                       = each.value.container_registry_key == null ? each.value.application_stack : merge(each.value.application_stack == null ? {} : each.value.application_stack, { docker_registry_url = "https://${module.container_registry[each.value.container_registry_key].login_server}" })
  container_registry_use_managed_identity = each.value.container_registry_key != null
  application_insights_connection_string  = each.value.application_insights_key == null ? null : module.application_insights[each.value.application_insights_key].connection_string
  app_settings                            = each.value.app_settings

  tags = merge(var.tags, { Purpose = each.key })
}

module "diag_web_app" {
  for_each = local.log_analytics_workspace_id != null ? var.web_apps : {}
  source   = "../../modules/diagnostic-setting"

  name                       = "diag-${module.web_app[each.key].name}"
  target_resource_id         = module.web_app[each.key].id
  log_analytics_workspace_id = local.log_analytics_workspace_id
}

module "function_app" {
  for_each = var.function_apps
  source   = "../../modules/azure-functions"

  name                = "func-${each.key}-${local.name_prefix}"
  service_plan_name   = "asp-func-${each.key}-${local.name_prefix}"
  location            = var.location
  resource_group_name = local.resource_group_name

  service_plan_sku_name                  = each.value.service_plan_sku_name
  storage_account_name                   = module.storage_account[each.value.storage_account_key].storage_account_name
  storage_account_access_key             = module.storage_account[each.value.storage_account_key].primary_access_key
  runtime                                = each.value.runtime
  public_network_access_enabled          = each.value.public_network_access_enabled
  virtual_network_subnet_id              = each.value.vnet_integration_subnet_key == null ? null : module.networking[0].subnet_ids[each.value.vnet_integration_subnet_key]
  application_insights_connection_string = each.value.application_insights_key == null ? null : module.application_insights[each.value.application_insights_key].connection_string
  app_settings                           = each.value.app_settings

  tags = merge(var.tags, { Purpose = each.key })
}

module "diag_function_app" {
  for_each = local.log_analytics_workspace_id != null ? var.function_apps : {}
  source   = "../../modules/diagnostic-setting"

  name                       = "diag-${module.function_app[each.key].name}"
  target_resource_id         = module.function_app[each.key].id
  log_analytics_workspace_id = local.log_analytics_workspace_id
}
