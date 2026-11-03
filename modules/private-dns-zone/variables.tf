variable "zone_name" {
  description = "Private DNS zone name, e.g. privatelink.vaultcore.azure.net. See the reference table in modules/private-endpoints/README.md for the zone name per Azure service."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the zone in — typically a hub/shared-services RG so it can be linked from every spoke."
  type        = string
}

variable "vnet_links" {
  description = "Map of link-name => VNet resource ID to link this zone to (hub + spokes)."
  type        = map(string)
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
