locals {
  service_plan_id = var.service_plan_id != null ? var.service_plan_id : azurerm_service_plan.this[0].id
  effective_app_settings = merge(var.app_settings, {
    FUNCTIONS_WORKER_RUNTIME = var.runtime.name
  })
}

resource "azurerm_service_plan" "this" {
  count = var.service_plan_id == null ? 1 : 0

  name                = var.service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.service_plan_sku_name

  tags = var.tags
}

resource "azurerm_linux_function_app" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = local.service_plan_id

  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key

  https_only                                     = true
  public_network_access_enabled                  = var.public_network_access_enabled
  virtual_network_subnet_id                      = var.virtual_network_subnet_id
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  functions_extension_version                    = "~4"
  app_settings                                   = local.effective_app_settings

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                              = var.always_on
    ftps_state                             = "Disabled"
    http2_enabled                          = true
    minimum_tls_version                    = "1.2"
    scm_minimum_tls_version                = "1.2"
    vnet_route_all_enabled                 = var.virtual_network_subnet_id != null
    application_insights_connection_string = var.application_insights_connection_string

    application_stack {
      dotnet_version              = contains(["dotnet", "dotnet-isolated"], var.runtime.name) ? var.runtime.version : null
      use_dotnet_isolated_runtime = var.runtime.name == "dotnet-isolated"
      java_version                = var.runtime.name == "java" ? var.runtime.version : null
      node_version                = var.runtime.name == "node" ? var.runtime.version : null
      powershell_core_version     = var.runtime.name == "powershell" ? var.runtime.version : null
      python_version              = var.runtime.name == "python" ? var.runtime.version : null
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.service_plan_id != null || var.service_plan_name != null
      error_message = "service_plan_name is required when service_plan_id is null."
    }
  }
}
