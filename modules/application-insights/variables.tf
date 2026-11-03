variable "name" {
  description = "Exact Application Insights component name."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "location" {
  description = "Azure region for the component."
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group name."
  type        = string
}

variable "workspace_id" {
  description = "Log Analytics workspace resource ID. This module creates workspace-based Application Insights only."
  type        = string

  validation {
    condition     = var.workspace_id != null && length(trimspace(var.workspace_id)) > 0
    error_message = "workspace_id must be a non-empty Log Analytics workspace resource ID."
  }
}

variable "application_type" {
  description = "Application type understood by Application Insights."
  type        = string
  default     = "web"

  validation {
    condition     = contains(["ios", "java", "MobileCenter", "Node.JS", "other", "phone", "store", "web"], var.application_type)
    error_message = "application_type is not supported by AzureRM."
  }
}

variable "daily_data_cap_in_gb" {
  description = "Daily telemetry ingestion cap in GB. Null uses the Azure default."
  type        = number
  default     = null

  validation {
    condition     = var.daily_data_cap_in_gb == null || var.daily_data_cap_in_gb > 0
    error_message = "daily_data_cap_in_gb must be null or greater than zero."
  }
}

variable "daily_data_cap_notifications_disabled" {
  description = "Disable email notifications when the daily cap is met."
  type        = bool
  default     = false
}

variable "retention_in_days" {
  description = "Application Insights retention in days."
  type        = number
  default     = 90
}

variable "sampling_percentage" {
  description = "Percentage of telemetry retained by ingestion sampling."
  type        = number
  default     = 100

  validation {
    condition     = var.sampling_percentage > 0 && var.sampling_percentage <= 100
    error_message = "sampling_percentage must be greater than zero and no more than 100."
  }
}

variable "disable_ip_masking" {
  description = "Disable IP masking. Keep false unless full client IP storage is approved."
  type        = bool
  default     = false
}

variable "local_authentication_disabled" {
  description = "Disable local/API-key authentication. Enable only when all telemetry producers use Microsoft Entra authentication."
  type        = bool
  default     = false
}

variable "internet_ingestion_enabled" {
  description = "Allow telemetry ingestion over the public endpoint."
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Allow queries over the public endpoint."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to the component."
  type        = map(string)
  default     = {}
}
