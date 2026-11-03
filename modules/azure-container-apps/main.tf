# Azure Container Apps Module
# Creates one Container App Environment with multiple Container Apps.
#
# Per CONVENTIONS.md:
#   #1 Names come from the caller: var.name_suffix (compute it in the root's
#      locals) and the resource group from the resource-group module. This
#      module creates no resource group of its own.
#   #4 Logs go to a caller-supplied Log Analytics workspace (e.g. the shared
#      landing-zone workspace) instead of a per-module workspace.
# Registry: pass an existing registry (e.g. from the container-registry
# module) in var.container_registry to wire image pulls and AcrPull RBAC.

# =====================================================
# CONTAINER APP ENVIRONMENT
# All apps in this module share this environment.
# For network isolation, deploy a separate module instance.
# =====================================================

resource "azurerm_container_app_environment" "env" {
  name                           = "cae-${var.name_suffix}"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.internal_load_balancer_enabled
  tags                           = var.tags
}

# =====================================================
# CONTAINER APPS
# One per entry in var.container_apps.
# =====================================================

resource "azurerm_container_app" "apps" {
  for_each = var.container_apps

  name                         = "ca-${each.key}-${var.name_suffix}"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = var.resource_group_name
  revision_mode                = each.value.revision_mode
  tags                         = var.tags

  # Secrets defined here can be referenced by name in secret_env_vars.
  dynamic "secret" {
    for_each = each.value.secrets
    content {
      name  = secret.key
      value = secret.value
    }
  }

  # SystemAssigned identity enables managed auth to ACR (no username/password needed)
  identity {
    type = "SystemAssigned"
  }

  # Pull from the caller-supplied registry with the app's managed identity
  dynamic "registry" {
    for_each = var.container_registry != null ? [var.container_registry] : []
    content {
      server   = registry.value.login_server
      identity = "system"
    }
  }

  template {
    min_replicas = each.value.min_replicas
    max_replicas = each.value.max_replicas

    container {
      name   = each.key
      image  = each.value.image
      cpu    = each.value.cpu
      memory = each.value.memory

      # Plain-text environment variables
      dynamic "env" {
        for_each = each.value.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      # Secret-backed environment variables (value = secret name)
      dynamic "env" {
        for_each = each.value.secret_env_vars
        content {
          name        = env.key
          secret_name = env.value
        }
      }
    }

    # HTTP-based autoscaling (optional)
    dynamic "http_scale_rule" {
      for_each = each.value.http_scale_rule_requests != null ? [each.value.http_scale_rule_requests] : []
      content {
        name                = "http-scaling"
        concurrent_requests = tostring(http_scale_rule.value)
      }
    }
  }

  # Ingress (external or internal)
  dynamic "ingress" {
    for_each = each.value.ingress_enabled ? [1] : []
    content {
      external_enabled = each.value.ingress_external
      target_port      = each.value.ingress_target_port
      transport        = each.value.ingress_transport

      traffic_weight {
        latest_revision = true
        percentage      = 100
      }
    }
  }
}

# =====================================================
# ACR PULL ROLE ASSIGNMENTS
# Grant each container app's managed identity AcrPull on the registry.
# Only created when var.container_registry is set.
# =====================================================

resource "azurerm_role_assignment" "acr_pull" {
  for_each = var.container_registry != null ? var.container_apps : {}

  scope                = var.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.apps[each.key].identity[0].principal_id
}
