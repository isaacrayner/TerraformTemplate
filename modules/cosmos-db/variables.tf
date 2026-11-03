# Input Variables for Cosmos DB Module

variable "name" {
  description = "Exact Cosmos DB account name — globally unique across Azure. Compute it in the calling root's locals — see CONVENTIONS.md #1."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{3,44}$", var.name))
    error_message = "Cosmos DB account name must be 3-44 lowercase alphanumeric characters or hyphens."
  }
}

variable "location" {
  description = "Azure region where the account (and its primary geo_location entry) will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where the Cosmos DB account will be created"
  type        = string
}

variable "kind" {
  description = "API surface: GlobalDocumentDB (SQL API, also the base for Cassandra/Gremlin/Table via capabilities), or MongoDB"
  type        = string
  default     = "GlobalDocumentDB"
  validation {
    condition     = contains(["GlobalDocumentDB", "MongoDB"], var.kind)
    error_message = "kind must be GlobalDocumentDB or MongoDB."
  }
}

variable "capabilities" {
  description = "Additional API capabilities, e.g. [\"EnableMongo\"], [\"EnableCassandra\"], [\"EnableGremlin\"], [\"EnableTable\"], [\"EnableServerless\"]. See Microsoft's capabilities reference — some are mutually exclusive."
  type        = list(string)
  default     = []
}

variable "geo_locations" {
  description = "Regions the account replicates to. Exactly one entry must have failover_priority = 0 (the write region unless multiple_write_locations is enabled)."
  type = list(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool, false)
  }))

  validation {
    condition     = length(var.geo_locations) > 0
    error_message = "At least one geo_location is required."
  }
}

variable "consistency_level" {
  description = "Default consistency level"
  type        = string
  default     = "Session"
  validation {
    condition     = contains(["Eventual", "ConsistentPrefix", "Session", "BoundedStaleness", "Strong"], var.consistency_level)
    error_message = "consistency_level must be one of Eventual, ConsistentPrefix, Session, BoundedStaleness, Strong."
  }
}

variable "max_interval_in_seconds" {
  description = "BoundedStaleness only: max lag in seconds between replicas"
  type        = number
  default     = null
}

variable "max_staleness_prefix" {
  description = "BoundedStaleness only: max number of stale requests tolerated"
  type        = number
  default     = null
}

variable "enable_automatic_failover" {
  description = "Enable automatic failover to the next-priority region on outage"
  type        = bool
  default     = false
}

variable "enable_multiple_write_locations" {
  description = "Enable multi-region writes (all geo_locations with the same failover_priority can write)"
  type        = bool
  default     = false
}

variable "enable_free_tier" {
  description = "Use the (one per subscription) free tier — 1000 RU/s + 25GB storage at no cost"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Whether the account's public endpoint exists at all. Defaults to false — CONVENTIONS.md #2's secure-by-default rule. Cosmos DB has no deny-by-default network ACL like Key Vault/Storage: it's an allow-list (ip_range_filter / virtual_network_subnet_ids) on the public endpoint, or no public endpoint at all. Set true only when deliberately choosing the public+allow-list model over a private endpoint."
  type        = bool
  default     = false
}

variable "ip_range_filter" {
  description = "Allow-listed public IP ranges. Only relevant when public_network_access_enabled = true."
  type        = list(string)
  default     = []
}

variable "virtual_network_subnet_ids" {
  description = "Subnet IDs granted access via VNet service endpoint (Microsoft.AzureCosmosDB). Setting this also flips is_virtual_network_filter_enabled on. This is a service-endpoint rule, not a private endpoint — call the private-endpoints module separately for a fully private path."
  type        = list(string)
  default     = []
}

variable "network_acl_bypass_for_azure_services" {
  description = "Allow trusted first-party Azure services (Data Factory, Stream Analytics, etc.) through the firewall regardless of ip_range_filter/virtual_network_subnet_ids. CONVENTIONS.md #2's AzureServices bypass, applied to Cosmos's own bypass flag."
  type        = bool
  default     = true
}

variable "backup_type" {
  description = "Periodic (scheduled snapshots) or Continuous (point-in-time restore)"
  type        = string
  default     = "Periodic"
  validation {
    condition     = contains(["Periodic", "Continuous"], var.backup_type)
    error_message = "backup_type must be Periodic or Continuous."
  }
}

variable "backup_interval_in_minutes" {
  description = "Periodic only: backup interval (60-1440)"
  type        = number
  default     = 240
}

variable "backup_retention_in_hours" {
  description = "Periodic only: backup retention (8-720)"
  type        = number
  default     = 720
}

variable "backup_storage_redundancy" {
  description = "Periodic only: Geo, Local, or Zone"
  type        = string
  default     = "Geo"
  validation {
    condition     = contains(["Geo", "Local", "Zone"], var.backup_storage_redundancy)
    error_message = "backup_storage_redundancy must be Geo, Local, or Zone."
  }
}

variable "continuous_tier" {
  description = "Continuous only: Continuous7Days or Continuous30Days"
  type        = string
  default     = "Continuous30Days"
  validation {
    condition     = contains(["Continuous7Days", "Continuous30Days"], var.continuous_tier)
    error_message = "continuous_tier must be Continuous7Days or Continuous30Days."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
