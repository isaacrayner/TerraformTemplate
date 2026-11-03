# Monitoring & Observability
# Application Insights, Log Analytics

# =====================================================
# LOG ANALYTICS WORKSPACE
# =====================================================
# A customer can supply a shared/hub workspace ID instead. In that case this
# deployment does not create a second workspace.
module "log_analytics" {
  count  = var.enable_log_analytics && var.log_analytics_workspace_id == null ? 1 : 0
  source = "../../modules/log-analytics"

  name                = "log-${local.name_prefix}"
  location            = var.location
  resource_group_name = local.resource_group_name

  retention_in_days = var.log_analytics_retention_in_days
  daily_quota_gb    = var.log_analytics_daily_quota_gb

  tags = var.tags
}

# Application Insights components are composed in applications.tf because they
# share lifecycle and settings with the workloads that emit telemetry.
