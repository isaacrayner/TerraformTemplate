# Input Variables for Storage Account Module

variable "name" {
  description = "Exact storage account name (3-24 chars, lowercase alphanumeric only — no hyphens). Compute it in the calling root's locals — see CONVENTIONS.md #1."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters, no hyphens."
  }
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where storage account will be created"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "Storage account replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Invalid replication type."
  }
}

variable "enable_https_only" {
  description = "Require HTTPS for storage account access"
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "Minimum TLS version for the storage account"
  type        = string
  default     = "TLS1_2"
  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "TLS version must be TLS1_0, TLS1_1, or TLS1_2."
  }
}

variable "blob_delete_retention_days" {
  description = "Number of days to retain deleted blobs"
  type        = number
  default     = 7
  validation {
    condition     = var.blob_delete_retention_days >= 1 && var.blob_delete_retention_days <= 365
    error_message = "Retention days must be between 1 and 365."
  }
}

variable "container_delete_retention_days" {
  description = "Number of days to retain deleted containers"
  type        = number
  default     = 7
  validation {
    condition     = var.container_delete_retention_days >= 1 && var.container_delete_retention_days <= 365
    error_message = "Retention days must be between 1 and 365."
  }
}

variable "blob_containers" {
  description = "List of blob container names to create"
  type        = list(string)
  default     = []
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
