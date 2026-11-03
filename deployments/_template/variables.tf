# Input Variables for Deployment

# =====================================================
# CORE VARIABLES (Required for All Deployments)
# =====================================================

variable "customer_short_name" {
  description = "Short name for the customer (3-8 lowercase characters, e.g., 'contoso')"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{3,8}$", var.customer_short_name))
    error_message = "Customer short name must be 3-8 lowercase letters only."
  }
}

variable "environment" {
  description = "Environment name (prod, dev, staging, uat, test)"
  type        = string
  validation {
    condition     = contains(["prod", "dev", "staging", "uat", "test"], var.environment)
    error_message = "Environment must be one of: prod, dev, staging, uat, test."
  }
}

variable "location" {
  description = "Azure region where resources will be deployed (e.g., 'eastus', 'westeurope')"
  type        = string
}

variable "location_code" {
  description = "Short code for the Azure region (e.g., 'eus' for East US, 'weu' for West Europe)"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2,4}$", var.location_code))
    error_message = "Location code must be 2-4 lowercase letters."
  }
}

variable "subscription_id" {
  description = "Azure subscription ID where resources will be deployed"
  type        = string
}

variable "instance_number" {
  description = "Instance number for resource naming (typically 1 for first deployment)"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

# =====================================================
# MODULE CONTROL FLAGS (Boolean)
# =====================================================

variable "enable_networking" {
  description = "Enable networking module (VNet, Subnets, NSGs)"
  type        = bool
  default     = true
}

# =====================================================
# STORAGE ACCOUNTS (Multiple Named Instances)
# =====================================================

variable "storage_accounts" {
  description = "Map of storage accounts to create. Key = suffix/purpose (e.g., 'data', 'logs', 'appX')"
  type = map(object({
    tier             = string       # Standard or Premium
    replication_type = string       # LRS, GRS, ZRS, GZRS, RAGRS, RAGZRS
    blob_containers  = list(string) # List of container names to create
    network_access = optional(object({
      default_action                = optional(string, "Deny")
      bypass                        = optional(list(string), ["AzureServices"])
      ip_rules                      = optional(list(string), [])
      subnet_ids                    = optional(list(string), [])
      public_network_access_enabled = optional(bool, true)
    }), {}) # CONVENTIONS.md #2 — override per instance to relax network access deliberately
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.storage_accounts : can(regex("^[a-z0-9]{1,10}$", k))])
    error_message = "Storage account keys (suffixes) must be 1-10 lowercase alphanumeric characters (no hyphens)."
  }
}

# =====================================================
# KEY VAULTS (Multiple Named Instances)
# =====================================================

variable "key_vaults" {
  description = "Map of Key Vaults to create. Key = suffix/purpose (e.g., 'secrets', 'certs', 'appX')"
  type = map(object({
    sku_name    = string # standard or premium
    enable_rbac = bool   # Use RBAC (recommended)
    network_access = optional(object({
      default_action                = optional(string, "Deny")
      bypass                        = optional(list(string), ["AzureServices"])
      ip_rules                      = optional(list(string), [])
      subnet_ids                    = optional(list(string), [])
      public_network_access_enabled = optional(bool, true)
    }), {}) # CONVENTIONS.md #2 — override per instance to relax network access deliberately
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.key_vaults : can(regex("^[a-z0-9-]{1,12}$", k))])
    error_message = "Key Vault keys (suffixes) must be 1-12 lowercase alphanumeric characters or hyphens."
  }
}

# =====================================================
# SQL DATABASES (Multiple Named Instances)
# =====================================================

variable "sql_databases" {
  description = "Map of SQL Servers and Databases to create. Key = suffix/purpose (e.g., 'orders', 'inventory', 'appX')"
  type = map(object({
    admin_username                = string         # SQL admin username
    admin_password                = string         # SQL admin password (use Key Vault reference)
    database_name                 = string         # Name of the database
    sku_name                      = string         # Basic, S0, S1, S2, P1, P2, etc.
    max_size_gb                   = number         # Maximum database size
    zone_redundant                = optional(bool) # Enable zone redundancy (default: false)
    public_network_access_enabled = optional(bool) # Default false (CONVENTIONS.md #2) — set true only to deliberately use the public+firewall model instead of a private endpoint
  }))
  default   = {}
  sensitive = true

  validation {
    condition     = alltrue([for k, v in var.sql_databases : can(regex("^[a-z0-9-]{1,15}$", k))])
    error_message = "SQL database keys (suffixes) must be 1-15 lowercase alphanumeric characters or hyphens."
  }
}

# =====================================================
# DIAGNOSTICS
# =====================================================

variable "enable_log_analytics" {
  description = "Create a deployment-local Log Analytics workspace when log_analytics_workspace_id is not supplied."
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Existing shared Log Analytics workspace resource ID. When set, this takes precedence and no deployment-local workspace is created."
  type        = string
  default     = null
}

variable "log_analytics_retention_in_days" {
  description = "Retention for a deployment-local Log Analytics workspace."
  type        = number
  default     = 30

  validation {
    condition     = var.log_analytics_retention_in_days >= 30 && var.log_analytics_retention_in_days <= 730
    error_message = "log_analytics_retention_in_days must be between 30 and 730."
  }
}

variable "log_analytics_daily_quota_gb" {
  description = "Daily ingestion quota for a deployment-local workspace. Use -1 for unlimited."
  type        = number
  default     = -1

  validation {
    condition     = var.log_analytics_daily_quota_gb == -1 || var.log_analytics_daily_quota_gb > 0
    error_message = "log_analytics_daily_quota_gb must be -1 or greater than zero."
  }
}

# =====================================================
# NETWORKING VARIABLES
# =====================================================

variable "vnet_address_space" {
  description = "Address space for the Virtual Network (e.g., ['10.0.0.0/16'])"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Map of subnets to create with their address prefixes"
  type = map(object({
    address_prefix    = string
    service_endpoints = optional(list(string))
  }))
  default = {
    gateway = {
      address_prefix = "10.0.0.0/24"
    }
    appservice = {
      address_prefix = "10.0.1.0/24"
    }
    vms = {
      address_prefix = "10.0.2.0/24"
    }
    data = {
      address_prefix = "10.0.3.0/24"
    }
    mgmt = {
      address_prefix = "10.0.255.0/24"
    }
  }
}

variable "existing_resource_group_name" {
  description = "Existing resource group name (if not using networking module)"
  type        = string
  default     = ""
}

# =====================================================
# STAGE 2 WORKLOADS
# =====================================================

variable "application_insights" {
  description = "Application Insights components keyed by workload name. Requires an effective Log Analytics workspace."
  type = map(object({
    application_type     = optional(string, "web")
    daily_data_cap_in_gb = optional(number)
    retention_in_days    = optional(number, 90)
    sampling_percentage  = optional(number, 100)
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.application_insights) : can(regex("^[a-z0-9-]{1,12}$", key))])
    error_message = "Application Insights keys must be 1-12 lowercase alphanumeric characters or hyphens."
  }
}

variable "container_registries" {
  description = "Container registries keyed by purpose."
  type = map(object({
    sku                           = optional(string, "Premium")
    public_network_access_enabled = optional(bool, false)
    export_policy_enabled         = optional(bool, false)
    zone_redundancy_enabled       = optional(bool, false)
    georeplications = optional(list(object({
      location                = string
      zone_redundancy_enabled = optional(bool, false)
      tags                    = optional(map(string), {})
    })), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.container_registries) : can(regex("^[a-z0-9]{1,10}$", key))])
    error_message = "Container Registry keys must be 1-10 lowercase alphanumeric characters."
  }
}

variable "web_apps" {
  description = "Linux Web Apps keyed by workload name. Use Key Vault reference strings rather than literal secrets in app_settings."
  type = map(object({
    service_plan_sku_name         = optional(string, "P1v3")
    public_network_access_enabled = optional(bool, false)
    vnet_integration_subnet_key   = optional(string)
    health_check_path             = optional(string)
    application_insights_key      = optional(string)
    container_registry_key        = optional(string)
    application_stack = optional(object({
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
    }))
    app_settings = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.web_apps) : can(regex("^[a-z0-9-]{1,12}$", key))])
    error_message = "Web App keys must be 1-12 lowercase alphanumeric characters or hyphens."
  }
}

variable "function_apps" {
  description = "Linux Function Apps keyed by workload name. Each references a storage account key in storage_accounts."
  type = map(object({
    service_plan_sku_name = optional(string, "EP1")
    storage_account_key   = string
    runtime = object({
      name    = string
      version = string
    })
    public_network_access_enabled = optional(bool, false)
    vnet_integration_subnet_key   = optional(string)
    application_insights_key      = optional(string)
    app_settings                  = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.function_apps) : can(regex("^[a-z0-9-]{1,12}$", key))])
    error_message = "Function App keys must be 1-12 lowercase alphanumeric characters or hyphens."
  }
}

variable "virtual_machines" {
  description = "SSH-only Linux VMs keyed by purpose."
  type = map(object({
    subnet_key                     = string
    size                           = optional(string, "Standard_D2s_v5")
    zone                           = optional(string)
    admin_username                 = optional(string, "azureadmin")
    admin_ssh_public_key           = string
    private_ip_address             = optional(string)
    public_ip_address_id           = optional(string)
    accelerated_networking_enabled = optional(bool, false)
    source_image = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = optional(string, "latest")
      }), {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
    })
    os_disk_storage_account_type = optional(string, "Premium_LRS")
    os_disk_size_gb              = optional(number)
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.virtual_machines) : can(regex("^[a-z0-9-]{1,12}$", key))])
    error_message = "Virtual Machine keys must be 1-12 lowercase alphanumeric characters or hyphens."
  }
}
