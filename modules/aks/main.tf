# Azure Kubernetes Service (AKS) Module

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = coalesce(var.dns_prefix, var.name)

  kubernetes_version = var.kubernetes_version
  sku_tier           = var.sku_tier

  role_based_access_control_enabled = true
  automatic_upgrade_channel         = var.automatic_upgrade_channel
  private_cluster_enabled           = var.private_cluster_enabled

  default_node_pool {
    name                         = var.default_node_pool.name
    vm_size                      = var.default_node_pool.vm_size
    vnet_subnet_id               = var.vnet_subnet_id
    auto_scaling_enabled         = var.default_node_pool.auto_scaling_enabled
    node_count                   = var.default_node_pool.auto_scaling_enabled ? null : var.default_node_pool.node_count
    min_count                    = var.default_node_pool.auto_scaling_enabled ? var.default_node_pool.min_count : null
    max_count                    = var.default_node_pool.auto_scaling_enabled ? var.default_node_pool.max_count : null
    zones                        = var.default_node_pool.availability_zones
    max_pods                     = var.default_node_pool.max_pods
    only_critical_addons_enabled = var.only_critical_addons_enabled
    # Lets Terraform stand up a same-config temp pool and migrate nodes over
    # instead of failing the apply when a change (e.g. vnet_subnet_id,
    # os_disk_size_gb) would otherwise force-replace the default node pool.
    temporary_name_for_rotation = "temppool"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = var.network_plugin
    network_plugin_mode = var.network_plugin == "azure" ? var.network_plugin_mode : null
    network_policy      = var.network_policy
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_azure_ad_rbac ? [1] : []
    content {
      azure_rbac_enabled     = true
      admin_group_object_ids = var.azure_ad_admin_group_object_ids
    }
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  lifecycle {
    precondition {
      condition     = var.default_node_pool.auto_scaling_enabled || var.default_node_pool.node_count != null
      error_message = "default_node_pool.node_count is required when default_node_pool.auto_scaling_enabled is false."
    }

    precondition {
      condition     = !var.default_node_pool.auto_scaling_enabled || (var.default_node_pool.min_count != null && var.default_node_pool.max_count != null)
      error_message = "default_node_pool.min_count and default_node_pool.max_count are required when default_node_pool.auto_scaling_enabled is true."
    }
  }

  tags = var.tags
}

# Additional (user workload) node pools — the default pool above stays
# system-only when only_critical_addons_enabled is true.
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = var.vnet_subnet_id
  os_type               = each.value.os_type
  mode                  = each.value.mode

  auto_scaling_enabled = each.value.auto_scaling_enabled
  node_count           = each.value.auto_scaling_enabled ? null : each.value.node_count
  min_count            = each.value.auto_scaling_enabled ? each.value.min_count : null
  max_count            = each.value.auto_scaling_enabled ? each.value.max_count : null

  zones       = each.value.availability_zones
  max_pods    = each.value.max_pods
  node_labels = each.value.node_labels
  node_taints = each.value.node_taints

  lifecycle {
    precondition {
      condition     = each.value.auto_scaling_enabled || each.value.node_count != null
      error_message = "node_count is required for additional_node_pools[\"${each.key}\"] when auto_scaling_enabled is false."
    }

    precondition {
      condition     = !each.value.auto_scaling_enabled || (each.value.min_count != null && each.value.max_count != null)
      error_message = "min_count and max_count are required for additional_node_pools[\"${each.key}\"] when auto_scaling_enabled is true."
    }
  }

  tags = var.tags
}
