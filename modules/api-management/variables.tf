# Input Variables for API Management Module

variable "name" {
  description = "Exact API Management service name — globally unique across Azure, forms the *.azure-api.net gateway hostname. Compute it in the calling root's locals — see CONVENTIONS.md #1."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,49}$", var.name))
    error_message = "API Management name must be 1-50 characters, start with a letter, and contain only letters, numbers, and hyphens."
  }
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where the API Management service will be created"
  type        = string
}

variable "publisher_name" {
  description = "Organization name shown in the developer portal and notification emails"
  type        = string
}

variable "publisher_email" {
  description = "Email address for service notifications"
  type        = string
}

variable "sku_name" {
  description = "SKU as \"{Tier}_{Capacity}\", e.g. \"Developer_1\", \"Premium_2\". Tier is Consumption, Developer, Basic, Standard, or Premium."
  type        = string
  default     = "Developer_1"
  validation {
    condition     = contains(["Consumption", "Developer", "Basic", "Standard", "Premium"], split("_", var.sku_name)[0])
    error_message = "sku_name tier (before the underscore) must be Consumption, Developer, Basic, Standard, or Premium."
  }
}

variable "public_network_access_enabled" {
  description = "Whether the service's public gateway/portal endpoints are reachable. Defaults to true — unlike Key Vault/Storage/SQL, API Management is fundamentally a public-facing gateway; CONVENTIONS.md #2 reserves a false default for resources that must be fully private (e.g. an ACA environment). Set false only on Premium with virtual_network_type = \"Internal\", where the gateway is meant to be VNet-only."
  type        = bool
  default     = true
}

variable "virtual_network_type" {
  description = "VNet integration mode: None, External (public gateway IP, private backends), or Internal (fully private gateway)"
  type        = string
  default     = "None"
  validation {
    condition     = contains(["None", "External", "Internal"], var.virtual_network_type)
    error_message = "virtual_network_type must be None, External, or Internal."
  }
}

variable "subnet_id" {
  description = "Subnet for VNet integration. Required when virtual_network_type is External or Internal. Needs a dedicated subnet (min /29, Microsoft recommend /24) with the required service endpoints — see README."
  type        = string
  default     = null
}

variable "identity_type" {
  description = "Managed identity type, or null for none"
  type        = string
  default     = null
  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "identity_type must be null, SystemAssigned, UserAssigned, or \"SystemAssigned, UserAssigned\"."
  }
}

variable "availability_zones" {
  description = "Availability zones for the primary location. Premium tier only."
  type        = list(string)
  default     = []
}

variable "min_api_version" {
  description = "Minimum API version callers must specify, or null for no restriction"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
