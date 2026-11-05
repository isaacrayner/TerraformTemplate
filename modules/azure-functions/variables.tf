variable "name" {
  description = "Globally unique Linux Function App name."
  type        = string
}

variable "location" {
  description = "Azure region for the function app and any created plan."
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group name."
  type        = string
}

variable "service_plan_id" {
  description = "Existing Linux App Service Plan ID. Null creates a plan."
  type        = string
  default     = null
}

variable "service_plan_name" {
  description = "Exact plan name when creating a plan."
  type        = string
  default     = null
}

variable "service_plan_sku_name" {
  description = "SKU for a created plan. EP1 supports private endpoints and VNet integration."
  type        = string
  default     = "EP1"
}

variable "storage_account_name" {
  description = "Storage account used by the Functions host."
  type        = string
}

variable "storage_account_access_key" {
  description = "Access key for the Functions host storage account."
  type        = string
  sensitive   = true
}

variable "runtime" {
  description = "Functions worker runtime and provider-supported version."
  type = object({
    name    = string
    version = string
  })

  validation {
    condition     = contains(["dotnet", "dotnet-isolated", "java", "node", "powershell", "python"], var.runtime.name)
    error_message = "runtime.name must be dotnet, dotnet-isolated, java, node, powershell, or python."
  }
}

variable "public_network_access_enabled" {
  description = "Expose the Function App public endpoint. Defaults false; compose a private endpoint in the root."
  type        = bool
  default     = false
}

variable "virtual_network_subnet_id" {
  description = "Optional delegated subnet ID for outbound VNet integration."
  type        = string
  default     = null
}

variable "always_on" {
  description = "Keep the worker loaded when supported by the plan."
  type        = bool
  default     = true
}

variable "application_insights_connection_string" {
  description = "Optional Application Insights connection string."
  type        = string
  default     = null
  sensitive   = true
}

variable "app_settings" {
  description = "Additional function app settings. Values are stored in Terraform state."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "tags" {
  description = "Tags applied to the plan and function app."
  type        = map(string)
  default     = {}
}
