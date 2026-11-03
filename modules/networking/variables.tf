# Input Variables for Networking Module

variable "name" {
  description = "Exact Virtual Network name. Compute it in the calling root's locals — see CONVENTIONS.md #1. Also used as the naming prefix for subnets/NSGs, e.g. snet-data-<name>."
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the VNet/subnets/NSGs are created in — create it with the resource-group module and pass its name here. This module does not create its own resource group (CONVENTIONS.md #1)."
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network (e.g., ['10.0.0.0/16'])"
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnets to create with their address prefixes"
  type = map(object({
    address_prefix = string
    # name: override the generated subnet name. Required for Azure-reserved names:
    #   "GatewaySubnet"        — VPN/ExpressRoute gateway (must be exactly this name)
    #   "AzureFirewallSubnet"  — Azure Firewall (must be exactly this name)
    #   "AzureBastionSubnet"   — Azure Bastion (must be exactly this name)
    # When omitted, the name is generated as "snet-{key}-{name}".
    name              = optional(string, null)
    service_endpoints = optional(list(string))
    # delegation: required for subnets used by ACA (service = "Microsoft.App/environments"),
    # App Service VNet integration, and other delegated services.
    delegation = optional(object({
      name    = string # arbitrary label, e.g. "aca-delegation"
      service = string # e.g. "Microsoft.App/environments"
      actions = optional(list(string), [])
    }))
  }))
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
