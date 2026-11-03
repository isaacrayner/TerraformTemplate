# Hub-to-Spoke VNet Peering
# Connects the hub VNet (Landing Zone subscription) to the spoke VNet (Compute subscription).
# Both directions must be created for traffic to flow.
#
# PREREQUISITES: enable_hub_networking = true AND enable_spoke_networking = true

locals {
  hub_spoke_peering_enabled = var.enable_hub_networking && var.enable_spoke_networking
}

# Hub → Spoke  (default provider — Landing Zone subscription)
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  count                        = local.hub_spoke_peering_enabled ? 1 : 0
  name                         = "peer-hub-to-spoke-${local.name_prefix}"
  resource_group_name          = local.shared_resource_group_name
  virtual_network_name         = module.hub_networking[0].vnet_name
  remote_virtual_network_id    = module.spoke_networking[0].vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  # Set allow_gateway_transit = true here if this hub has a VPN/ER gateway and you
  # want spoke VMs to route through it. Also set use_remote_gateways = true on spoke_to_hub.
  allow_gateway_transit = false
}

# Spoke → Hub  (azurerm.compute provider — Compute subscription)
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count                        = local.hub_spoke_peering_enabled ? 1 : 0
  provider                     = azurerm.compute
  name                         = "peer-spoke-to-hub-${local.name_prefix}"
  resource_group_name          = local.resource_group_name
  virtual_network_name         = module.spoke_networking[0].vnet_name
  remote_virtual_network_id    = module.hub_networking[0].vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  # Set use_remote_gateways = true here if the hub has a VPN/ER gateway you want to use.
  # Requires allow_gateway_transit = true on hub_to_spoke first.
  use_remote_gateways = false
}
