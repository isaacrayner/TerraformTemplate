# Input Variables for Key Vault Module

variable "name" {
  description = "Exact Key Vault name (3-24 chars, alphanumeric and hyphens). Compute it in the calling root's locals — see CONVENTIONS.md #1."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.name))
    error_message = "Key Vault name must be 3-24 characters, alphanumeric and hyphens only."
  }
}

variable "location" {
  description = "Azure region where the Key Vault will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where Key Vault will be created"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID for the Key Vault"
  type        = string
}

variable "sku_name" {
  description = "Key Vault SKU (standard or premium)"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU must be standard or premium."
  }
}

variable "enable_rbac_authorization" {
  description = "Enable RBAC authorization for Key Vault (recommended over access policies)"
  type        = bool
  default     = true
}

variable "enabled_for_disk_encryption" {
  description = "Enable Key Vault for Azure Disk Encryption"
  type        = bool
  default     = true
}

variable "enabled_for_deployment" {
  description = "Enable Key Vault for VM deployment"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Enable Key Vault for ARM template deployment"
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain deleted Key Vault and secrets (7-90 days)"
  type        = number
  default     = 90
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Retention days must be between 7 and 90."
  }
}

variable "purge_protection_enabled" {
  description = "Enable purge protection (prevents permanent deletion during retention period)"
  type        = bool
  default     = true
}

variable "network_access" {
  description = "Network access policy. See CONVENTIONS.md #2. Defaults to secure: public endpoint present but firewalled to AzureServices only."
  type = object({
    default_action                = optional(string, "Deny") # Allow | Deny
    bypass                        = optional(list(string), ["AzureServices"])
    ip_rules                      = optional(list(string), [])
    subnet_ids                    = optional(list(string), [])
    public_network_access_enabled = optional(bool, true)
  })
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
