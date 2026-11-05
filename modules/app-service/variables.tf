variable "name" {
  description = "Globally unique Linux Web App name."
  type        = string
}

variable "location" {
  description = "Azure region for the app and any created plan."
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group name."
  type        = string
}

variable "service_plan_id" {
  description = "Existing Linux App Service Plan ID. Null creates a plan in this module."
  type        = string
  default     = null
}

variable "service_plan_name" {
  description = "Exact plan name when creating a plan. Required when service_plan_id is null."
  type        = string
  default     = null
}

variable "service_plan_sku_name" {
  description = "SKU for a plan created by this module."
  type        = string
  default     = "P1v3"
}

variable "service_plan_worker_count" {
  description = "Worker count for a plan created by this module."
  type        = number
  default     = 1

  validation {
    condition     = var.service_plan_worker_count >= 1
    error_message = "service_plan_worker_count must be at least 1."
  }
}

variable "service_plan_zone_balancing_enabled" {
  description = "Enable zone balancing on a supported plan SKU."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Expose the app public endpoint. Defaults false; compose private connectivity in the root."
  type        = bool
  default     = false
}

variable "virtual_network_subnet_id" {
  description = "Optional delegated subnet ID for outbound VNet integration."
  type        = string
  default     = null
}

variable "always_on" {
  description = "Keep the worker loaded when supported by the selected plan."
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Optional health endpoint path, for example /health."
  type        = string
  default     = null
}

variable "container_registry_use_managed_identity" {
  description = "Use the web app managed identity to pull a private container image. Grant AcrPull in the calling root."
  type        = bool
  default     = false
}

variable "application_stack" {
  description = "Optional Linux runtime or container stack. Set only the fields required by one stack."
  type = object({
    docker_image_name   = optional(string)
    docker_registry_url = optional(string)
    dotnet_version      = optional(string)
    go_version          = optional(string)
    java_server         = optional(string)
    java_server_version = optional(string)
    java_version        = optional(string)
    node_version        = optional(string)
    php_version         = optional(string)
    python_version      = optional(string)
  })
  default = null
}

variable "application_insights_connection_string" {
  description = "Optional Application Insights connection string added to app settings."
  type        = string
  default     = null
  sensitive   = true
}

variable "app_settings" {
  description = "Application settings. Values are stored in Terraform state; prefer Key Vault references over literal secrets."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "tags" {
  description = "Tags applied to the plan and web app."
  type        = map(string)
  default     = {}
}
