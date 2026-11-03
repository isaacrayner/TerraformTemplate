# Input Variables for Redis Cache Module

variable "name" {
  description = "Exact Redis Cache name (lowercase, numbers, hyphens). Compute it in the calling root's locals — see CONVENTIONS.md #1."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{1,63}$", var.name))
    error_message = "Redis Cache name must be 1-63 lowercase alphanumeric characters or hyphens."
  }
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where the Redis Cache will be created"
  type        = string
}

variable "sku_name" {
  description = "SKU tier (Basic, Standard, or Premium)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "sku_name must be Basic, Standard, or Premium."
  }
}

variable "family" {
  description = "SKU family: C for Basic/Standard, P for Premium"
  type        = string
  default     = "C"
  validation {
    condition     = contains(["C", "P"], var.family)
    error_message = "family must be C (Basic/Standard) or P (Premium)."
  }
}

variable "capacity" {
  description = "Cache size. Family C: 0-6 (250MB-53GB). Family P: 1-5 (6GB-120GB)."
  type        = number
  default     = 1
}

variable "non_ssl_port_enabled" {
  description = "Allow access via the non-TLS port 6379. Leave false unless a legacy client requires it."
  type        = bool
  default     = false
}

variable "minimum_tls_version" {
  description = "Minimum TLS version accepted by the cache"
  type        = string
  default     = "1.2"
  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "minimum_tls_version must be 1.0, 1.1, or 1.2."
  }
}

variable "maxmemory_policy" {
  description = "Eviction policy once maxmemory is reached"
  type        = string
  default     = "volatile-lru"
  validation {
    condition = contains([
      "volatile-lru", "volatile-lfu", "volatile-random", "volatile-ttl",
      "allkeys-lru", "allkeys-lfu", "allkeys-random", "noeviction"
    ], var.maxmemory_policy)
    error_message = "maxmemory_policy must be a valid Redis eviction policy."
  }
}

variable "public_network_access_enabled" {
  description = "Whether the cache's public endpoint exists at all. Defaults to false — CONVENTIONS.md #2's secure-by-default rule. Like SQL Server, Redis has no partial-firewall equivalent to Key Vault/Storage's deny-by-default network ACL: it's either a private-endpoint-only cache, or a public one gated by allowed_ip_ranges. Set true only when you're deliberately choosing the public+firewall model over a private endpoint."
  type        = bool
  default     = false
}

variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges for firewall rules. Only relevant when public_network_access_enabled = true."
  type = list(object({
    name     = string
    start_ip = string
    end_ip   = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
