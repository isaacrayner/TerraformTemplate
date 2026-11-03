# Networking Module - Virtual Network and Subnets
#
# Does not create its own resource group — take resource_group_name from the
# resource-group module (CONVENTIONS.md #1). It previously created one inline,
# which duplicated naming logic the caller already owns and made this module
# impossible to compose into an existing resource group.

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

  name                 = "snet-${each.key}-${var.name}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.address_prefix]

  # service_endpoints is a plain list(string) attribute on azurerm_subnet,
  # not a nested block — a `dynamic "service_endpoints"` block here can never
  # validate. Fixed 2026-08-14 while validating newly-ported modules; this
  # module had never actually been run through `terraform validate`.
  service_endpoints = lookup(each.value, "service_endpoints", null)
}

# Network Security Groups (one per subnet)
resource "azurerm_network_security_group" "nsg" {
  for_each = var.subnets

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

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}
