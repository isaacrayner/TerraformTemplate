# Module: diagnostic-setting
# Ships a resource's logs (category group, default "allLogs") and optionally
# metrics to a Log Analytics workspace. Cross-subscription workspace targets
# work within one tenant — use this to ship spoke resources to a hub workspace.

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = var.name
  target_resource_id         = var.target_resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = toset(var.log_category_groups)
    content {
      category_group = enabled_log.value
    }
  }

  dynamic "enabled_metric" {
    for_each = var.metrics_enabled ? ["AllMetrics"] : []
    content {
      category = enabled_metric.value
    }
  }
}
