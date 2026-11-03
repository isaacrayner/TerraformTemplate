variable "name" {
  description = "Exact Log Analytics workspace name. Compute it in the calling root; see CONVENTIONS.md."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]{2,61}[A-Za-z0-9]$", var.name))
    error_message = "Log Analytics workspace name must be 4-63 letters, digits, or hyphens and cannot start or end with a hyphen."
  }
}

variable "location" {
  description = "Azure region in which to create the workspace."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the workspace."
  type        = string
}

variable "sku" {
  description = "Log Analytics pricing SKU. PerGB2018 is the normal pay-as-you-go choice."
  type        = string
  default     = "PerGB2018"

  validation {
    condition = contains([
      "PerGB2018",
      "PerNode",
      "Premium",
      "Standalone",
      "Standard",
      "CapacityReservation",
      "LACluster",
      "Unlimited"
    ], var.sku)
    error_message = "sku must be a value supported by azurerm_log_analytics_workspace."
  }
}

variable "retention_in_days" {
  description = "Workspace data retention in days."
  type        = number
  default     = 30

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "retention_in_days must be between 30 and 730."
  }
}

variable "daily_quota_gb" {
  description = "Daily ingestion quota in GB. Use -1 for unlimited."
  type        = number
  default     = -1

  validation {
    condition     = var.daily_quota_gb == -1 || var.daily_quota_gb > 0
    error_message = "daily_quota_gb must be -1 (unlimited) or greater than zero."
  }
}

variable "local_authentication_enabled" {
  description = "Allow shared-key authentication in addition to Microsoft Entra authentication. Disable only after confirming every integration supports Entra authentication."
  type        = bool
  default     = true
}

variable "internet_ingestion_enabled" {
  description = "Allow telemetry ingestion through the public endpoint."
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Allow queries through the public endpoint."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the workspace."
  type        = map(string)
  default     = {}
}
