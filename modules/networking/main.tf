# Networking Module - Virtual Network and Subnets
#
# Does not create its own resource group — take resource_group_name from the
# resource-group module (CONVENTIONS.md #1). It previously created one inline,
# which duplicated naming logic the caller already owns and made this module
# impossible to compose into an existing resource group.

locals {
  # Azure-reserved subnet names that prohibit NSG attachment.
  # GatewaySubnet: VPN/ExpressRoute gateway.
  # AzureFirewallSubnet: Azure Firewall manages its own rules.
  no_nsg_names = toset(["GatewaySubnet", "AzureFirewallSubnet"])

  # Subnets that receive an NSG: filters out Azure-reserved names using the
  # override name (if set) or the map key as a fallback.
  nsg_subnets = {
    for k, v in var.subnets : k => v
    if !contains(local.no_nsg_names, coalesce(v.name, k))
  }
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  # Use the override name when provided (e.g. "GatewaySubnet"); otherwise generate a standard name.
  name                 = coalesce(each.value.name, "snet-${each.key}-${var.name}")
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.address_prefix]

  # service_endpoints is a plain list(string) attribute on azurerm_subnet,
  # not a nested block — a `dynamic "service_endpoints"` block here can never
  # validate. Fixed 2026-08-14 while validating newly-ported modules; this
  # module had never actually been run through `terraform validate`.
  service_endpoints = lookup(each.value, "service_endpoints", null)

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service
        actions = delegation.value.actions
      }
    }
  }
}

# Network Security Groups (one per subnet, excluding Azure-reserved subnets)
resource "azurerm_network_security_group" "nsg" {
  for_each = local.nsg_subnets

  name                = "nsg-${each.key}-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Default deny all inbound rule (best practice - explicit rules should be added per customer)
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSGs with Subnets (only non-reserved subnets)
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each = local.nsg_subnets

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}
