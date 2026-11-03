# Input Variables for AKS Module

variable "name" {
  description = "Exact AKS cluster name. Compute it in the calling root's locals — see CONVENTIONS.md #1."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_]{0,62}$", var.name))
    error_message = "AKS cluster name must be 1-63 characters, start alphanumeric, and contain only letters, numbers, hyphens, and underscores."
  }
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where the AKS cluster will be created"
  type        = string
}

variable "vnet_subnet_id" {
  description = "Subnet for the default node pool (and every additional_node_pools entry, since AKS clusters normally share one node subnet). Azure CNI Overlay (the default network_plugin_mode) needs far fewer IPs than classic Azure CNI — see README."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the cluster's API server FQDN. Defaults to name."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version, or null to let Azure assign its current default"
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "Control plane tier: Free (no SLA), Standard (99.95% SLA), or Premium (adds long-term support)"
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be Free, Standard, or Premium."
  }
}

variable "automatic_upgrade_channel" {
  description = "Automatic upgrade channel: none, patch, stable, rapid, or node-image"
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "patch", "stable", "rapid", "node-image"], var.automatic_upgrade_channel)
    error_message = "automatic_upgrade_channel must be none, patch, stable, rapid, or node-image."
  }
}

variable "private_cluster_enabled" {
  description = "Make the API server reachable only from the VNet (via a private endpoint Azure manages)"
  type        = bool
  default     = false
}

variable "only_critical_addons_enabled" {
  description = "Taint the default node pool so only critical system add-ons schedule on it, forcing workloads onto additional_node_pools. Only useful once at least one additional node pool exists."
  type        = bool
  default     = false
}

variable "default_node_pool" {
  description = "The mandatory system node pool. Exactly one of node_count, or the min_count/max_count pair, applies depending on auto_scaling_enabled."
  type = object({
    name                 = optional(string, "system")
    vm_size              = optional(string, "Standard_D2s_v5")
    node_count           = optional(number, 2)
    auto_scaling_enabled = optional(bool, true)
    min_count            = optional(number, 2)
    max_count            = optional(number, 5)
    max_pods             = optional(number)
    availability_zones   = optional(list(string), [])
  })
  default = {}
}

variable "additional_node_pools" {
  description = "User workload node pools keyed by pool name (1-12 lowercase alphanumeric characters, AKS's own naming limit)."
  type = map(object({
    vm_size              = string
    os_type              = optional(string, "Linux")
    mode                 = optional(string, "User")
    node_count           = optional(number, 2)
    auto_scaling_enabled = optional(bool, true)
    min_count            = optional(number, 2)
    max_count            = optional(number, 5)
    max_pods             = optional(number)
    availability_zones   = optional(list(string), [])
    node_labels          = optional(map(string), {})
    node_taints          = optional(list(string), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.additional_node_pools) : can(regex("^[a-z][a-z0-9]{0,11}$", k))])
    error_message = "additional_node_pools keys must be 1-12 lowercase alphanumeric characters, starting with a letter."
  }
}

variable "network_plugin" {
  description = "azure (Azure CNI) or kubenet. kubenet is on Microsoft's deprecation path for new clusters — prefer azure with network_plugin_mode = \"overlay\" unless you specifically need kubenet's simpler subnet-independent routing."
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "network_plugin must be azure or kubenet."
  }
}

variable "network_plugin_mode" {
  description = "Only used when network_plugin = \"azure\". \"overlay\" (Azure CNI Overlay, the current Microsoft-recommended default) assigns pod IPs from an overlay CIDR instead of the node subnet, so the subnet only needs enough IPs for nodes — like kubenet, without kubenet's limitations. Set to null for classic (non-overlay) Azure CNI, which needs a much larger subnet (see README)."
  type        = string
  default     = "overlay"
  validation {
    condition     = var.network_plugin_mode == null || var.network_plugin_mode == "overlay"
    error_message = "network_plugin_mode must be \"overlay\" or null."
  }
}

variable "network_policy" {
  description = "Network policy engine: azure, calico, cilium, or null for none"
  type        = string
  default     = null
}

variable "service_cidr" {
  description = "CIDR for the Kubernetes service address range, or null to let Azure assign a default. Must not overlap any VNet address space this cluster can reach."
  type        = string
  default     = null
}

variable "dns_service_ip" {
  description = "IP within service_cidr for the cluster's DNS service, or null to let Azure assign a default"
  type        = string
  default     = null
}

variable "enable_azure_ad_rbac" {
  description = "Enable Entra ID-integrated Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = false
}

variable "azure_ad_admin_group_object_ids" {
  description = "Entra group object IDs granted cluster-admin. Only relevant when enable_azure_ad_rbac = true."
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for Container Insights (the oms_agent add-on), or null to skip it"
  type        = string
  default     = null
}

variable "api_server_authorized_ip_ranges" {
  description = "Public IP ranges allowed to reach the API server. Empty list leaves the API server open to the internet (or VNet-only if private_cluster_enabled is true) — set this for any non-private cluster with a real security requirement."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
