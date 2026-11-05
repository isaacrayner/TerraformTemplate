variable "name" {
  description = "Globally unique registry name, 5-50 lowercase alphanumeric characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{5,50}$", var.name))
    error_message = "Container Registry name must be 5-50 lowercase alphanumeric characters."
  }
}

variable "location" {
  description = "Azure region for the registry."
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group name."
  type        = string
}

variable "sku" {
  description = "Registry SKU. Premium is the default because private networking is the secure default."
  type        = string
  default     = "Premium"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable the registry-local administrator account. Keep disabled and use managed identity/RBAC."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Expose the registry public endpoint. Defaults false; compose a private endpoint in the customer root."
  type        = bool
  default     = false
}

variable "export_policy_enabled" {
  description = "Permit artifact export. Defaults false to reduce data-exfiltration paths."
  type        = bool
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy in the primary region. Premium only."
  type        = bool
  default     = false
}

variable "georeplications" {
  description = "Premium-only replica regions."
  type = list(object({
    location                = string
    zone_redundancy_enabled = optional(bool, false)
    tags                    = optional(map(string), {})
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the registry and replicas."
  type        = map(string)
  default     = {}
}
