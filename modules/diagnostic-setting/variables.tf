variable "name" {
  description = "Diagnostic setting name, e.g. diag-kv-contoso-prod-uks-001."
  type        = string
}

variable "target_resource_id" {
  description = "Resource ID of the resource whose logs/metrics are shipped."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Destination Log Analytics workspace resource ID."
  type        = string
}

variable "log_category_groups" {
  description = "Log category groups to enable. \"allLogs\" covers every category the resource type exposes. Set [] for metrics-only resources."
  type        = list(string)
  default     = ["allLogs"]
}

variable "metrics_enabled" {
  description = "Ship AllMetrics too. Set false for resource types with no metrics (e.g. NSGs)."
  type        = bool
  default     = true
}

# No "tags" variable — azurerm_monitor_diagnostic_setting doesn't accept one
# (Azure API limitation, not a config choice).
