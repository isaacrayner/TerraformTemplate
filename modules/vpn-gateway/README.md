# VPN Gateway Module

This module creates an Azure VPN Gateway for site-to-site, point-to-site, or VNet-to-VNet connectivity.

## Features

- VPN Gateway (VpnGw1, VpnGw2, VpnGw3, etc.)
- Public IP for gateway
- Gateway subnet configuration
- Local Network Gateway (for site-to-site)
- VPN connections
- Point-to-site configuration
- BGP support
- Active-active mode support
- Custom IPsec/IKE policies

## Usage

```hcl
module "vpn_gateway" {
  source = "../../modules/vpn-gateway"
  
  customer_short_name = var.customer_short_name
  environment         = var.environment
  location            = var.location
  location_code       = var.location_code
  resource_group_name = azurerm_resource_group.main.name
  
  virtual_network_name = module.networking.vnet_name
  gateway_subnet_id    = module.networking.gateway_subnet_id
  
  gateway_sku  = "VpnGw2"
  gateway_type = "Vpn"
  vpn_type     = "RouteBased"
  
  enable_bgp           = false
  enable_active_active = false
  
  # Site-to-Site Configuration
  local_networks = {
    onprem = {
      gateway_address = "203.0.113.10"
      address_space   = ["192.168.0.0/16"]
    }
  }
  
  # Point-to-Site Configuration (optional)
  enable_point_to_site = true
  vpn_client_configuration = {
    address_space        = ["172.16.0.0/24"]
    vpn_client_protocols = ["OpenVPN", "IkeV2"]
  }
  
  tags = var.tags
}
```

## Variables

### Required Variables

- `customer_short_name` - Short name for the customer (3-8 characters)
- `environment` - Environment name (prod, dev, staging)
- `location` - Azure region
- `location_code` - Short region code (eus, wus, etc.)
- `resource_group_name` - Name of the resource group
- `virtual_network_name` - Name of the virtual network
- `gateway_subnet_id` - ID of the gateway subnet

### Optional Variables

- `instance_number` - Instance number for naming (default: 1)
- `gateway_sku` - VPN Gateway SKU (default: "VpnGw1")
  - Options: VpnGw1, VpnGw2, VpnGw3, VpnGw4, VpnGw5, VpnGw1AZ, VpnGw2AZ, VpnGw3AZ
- `gateway_type` - Gateway type (default: "Vpn")
- `vpn_type` - VPN type (default: "RouteBased")
- `enable_bgp` - Enable BGP (default: false)
- `enable_active_active` - Enable active-active mode (default: false)
- `local_networks` - Map of local network gateways for site-to-site
- `enable_point_to_site` - Enable point-to-site VPN (default: false)
- `vpn_client_configuration` - Point-to-site configuration
- `custom_ipsec_policy` - Custom IPsec/IKE policy
- `tags` - Resource tags

## Outputs

- `vpn_gateway_id` - VPN Gateway resource ID
- `vpn_gateway_name` - VPN Gateway name
- `public_ip_address` - VPN Gateway public IP address
- `local_network_gateway_ids` - Map of local network gateway IDs
- `vpn_connection_ids` - Map of VPN connection IDs

## Resource Naming

Resources created by this module follow the naming convention:

- VPN Gateway: `vpngw-{customer}-{env}-{region}-{instance}`
- Public IP: `pip-vpngw-{customer}-{env}-{region}-{instance}`
- Local Network Gateway: `lng-{name}-{customer}-{env}-{region}-{instance}`
- VPN Connection: `cn-{name}-{customer}-{env}-{region}-{instance}`

## SKU Comparison

| SKU | Tunnels | P2S Connections | Throughput | BGP | Availability Zones |
|-----|---------|-----------------|------------|-----|-------------------|
| VpnGw1 | 30 | 250 | 650 Mbps | Yes | No |
| VpnGw2 | 30 | 500 | 1 Gbps | Yes | No |
| VpnGw3 | 30 | 1000 | 1.25 Gbps | Yes | No |
| VpnGw1AZ | 30 | 250 | 650 Mbps | Yes | Yes |
| VpnGw2AZ | 30 | 500 | 1 Gbps | Yes | Yes |
| VpnGw3AZ | 30 | 1000 | 1.25 Gbps | Yes | Yes |

## Security Considerations

- Use strong shared keys for site-to-site connections
- Store connection strings in Key Vault
- Enable Azure AD authentication for point-to-site
- Use certificate-based authentication when possible
- Configure custom IPsec/IKE policies for enhanced security
- Enable diagnostic logging
- Use private link for management when possible

## Dependencies

- Requires a virtual network with gateway subnet
- Gateway subnet must be named "GatewaySubnet"
- Gateway subnet should be at least /27 or larger
- Requires public IP resource

## Notes

- VPN Gateway deployment takes 30-45 minutes
- Gateway subnet cannot have NSG attached
- Active-active mode requires two public IPs
- BGP requires dynamic routing VPN type
- Point-to-site supports up to 1000 concurrent connections (VpnGw3)
- Consider using Azure ExpressRoute for high-bandwidth requirements
