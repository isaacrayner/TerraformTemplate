locals {
  service_plan_id = var.service_plan_id != null ? var.service_plan_id : azurerm_service_plan.this[0].id
  effective_app_settings = merge(
    var.app_settings,
    var.application_insights_connection_string == null ? {} : {
      APPLICATIONINSIGHTS_CONNECTION_STRING = var.application_insights_connection_string
    }
  )
}

resource "azurerm_service_plan" "this" {
  count = var.service_plan_id == null ? 1 : 0

  name                   = var.service_plan_name
  location               = var.location
  resource_group_name    = var.resource_group_name
  os_type                = "Linux"
  sku_name               = var.service_plan_sku_name
  worker_count           = var.service_plan_worker_count
  zone_balancing_enabled = var.service_plan_zone_balancing_enabled

  tags = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = local.service_plan_id

  https_only                                     = true
  public_network_access_enabled                  = var.public_network_access_enabled
  virtual_network_subnet_id                      = var.virtual_network_subnet_id
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  app_settings                                   = local.effective_app_settings

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                               = var.always_on
    ftps_state                              = "Disabled"
    http2_enabled                           = true
    minimum_tls_version                     = "1.2"
    scm_minimum_tls_version                 = "1.2"
    health_check_path                       = var.health_check_path
    vnet_route_all_enabled                  = var.virtual_network_subnet_id != null
    container_registry_use_managed_identity = var.container_registry_use_managed_identity

    dynamic "application_stack" {
      for_each = var.application_stack == null ? [] : [var.application_stack]
      content {
        docker_image_name   = application_stack.value.docker_image_name
        docker_registry_url = application_stack.value.docker_registry_url
        dotnet_version      = application_stack.value.dotnet_version
        go_version          = application_stack.value.go_version
        java_server         = application_stack.value.java_server
        java_server_version = application_stack.value.java_server_version
        java_version        = application_stack.value.java_version
        node_version        = application_stack.value.node_version
        php_version         = application_stack.value.php_version
        python_version      = application_stack.value.python_version
      }
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.service_plan_id != null || var.service_plan_name != null
      error_message = "service_plan_name is required when service_plan_id is null."
    }

    precondition {
      condition = !var.container_registry_use_managed_identity || (
        var.application_stack != null &&
        var.application_stack.docker_image_name != null &&
        var.application_stack.docker_registry_url != null
      )
      error_message = "A managed-identity container deployment requires application_stack.docker_image_name and docker_registry_url."
    }
  }
}
