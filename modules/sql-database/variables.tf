# Input Variables for SQL Database Module

variable "name" {
  description = "Exact SQL Server name (lowercase, numbers, hyphens). Compute it in the calling root's locals — see CONVENTIONS.md #1."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{1,63}$", var.name))
    error_message = "SQL Server name must be 1-63 lowercase alphanumeric characters or hyphens."
  }
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where SQL Server will be created"
  type        = string
}

variable "sql_version" {
  description = "SQL Server version"
  type        = string
  default     = "12.0"
}

variable "admin_username" {
  description = "Administrator username for SQL Server"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Administrator password for SQL Server (should be from Key Vault)"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Password must be at least 12 characters long."
  }
}

variable "database_name" {
  description = "Name of the SQL Database"
  type        = string
}

variable "sku_name" {
  description = "SKU name for the database (e.g., Basic, S0, S1, P1)"
  type        = string
  default     = "S1"
}

variable "max_size_gb" {
  description = "Maximum size of the database in gigabytes"
  type        = number
  default     = 250
}

variable "collation" {
  description = "Database collation"
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "zone_redundant" {
  description = "Enable zone redundancy for the database"
  type        = bool
  default     = false
}

variable "enable_azure_ad_admin" {
  description = "Enable Azure AD administrator for SQL Server"
  type        = bool
  default     = false
}

variable "azure_ad_admin_login" {
  description = "Azure AD admin login name"
  type        = string
  default     = null
}

variable "azure_ad_admin_object_id" {
  description = "Azure AD admin object ID"
  type        = string
  default     = null
}

variable "azure_ad_only_auth" {
  description = "Enable Azure AD only authentication (no SQL auth)"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Whether the server's public endpoint exists at all. Defaults to false — CONVENTIONS.md #2's secure-by-default rule. SQL Server has no partial-firewall equivalent to Key Vault/Storage's deny-by-default network ACL: it's either a private-endpoint-only server, or a public one gated by allowed_ip_ranges/allow_azure_services. Set true only when you're deliberately choosing the public+firewall model over a private endpoint."
  type        = bool
  default     = false
}

variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges for firewall rules. Only relevant when public_network_access_enabled = true."
  type = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
  }))
  default = []
}

variable "allow_azure_services" {
  description = "Allow Azure services to access the SQL Server. Only relevant when public_network_access_enabled = true."
  type        = bool
  default     = true
}

variable "enable_advanced_threat_protection" {
  description = "Enable advanced threat protection"
  type        = bool
  default     = true
}

variable "threat_detection_email_admins" {
  description = "Send threat detection alerts to account admins"
  type        = bool
  default     = true
}

variable "threat_detection_emails" {
  description = "List of email addresses for threat detection alerts"
  type        = list(string)
  default     = []
}

variable "threat_detection_retention_days" {
  description = "Number of days to retain threat detection logs"
  type        = number
  default     = 30
}

variable "enable_auditing" {
  description = "Enable SQL Server auditing"
  type        = bool
  default     = false
}

variable "audit_storage_endpoint" {
  description = "Storage endpoint for audit logs"
  type        = string
  default     = null
}

variable "audit_retention_days" {
  description = "Number of days to retain audit logs"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
