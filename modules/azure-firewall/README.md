# Azure Firewall Module

This module creates an Azure Firewall for network security and traffic filtering.

## Features

- Azure Firewall (Standard or Premium tier)
- Firewall Policy with rule collections
- Public IP address(es)
- DNS proxy configuration
- Threat intelligence filtering
- IDPS (Intrusion Detection and Prevention System) - Premium tier
- TLS inspection - Premium tier
- Diagnostic logging
- Forced tunneling support
- Availability zones support

## Usage

```hcl
module "azure_firewall" {
  source = "../../modules/azure-firewall"
  
  customer_short_name = var.customer_short_name
  environment         = var.environment
  location            = var.location
  location_code       = var.location_code
  resource_group_name = azurerm_resource_group.main.name
  
  # Firewall Configuration
  sku_tier = "Standard"  # or "Premium"
  
  # Networking
  virtual_network_name     = module.networking.vnet_name
  firewall_subnet_id       = module.networking.firewall_subnet_id
  firewall_subnet_prefix   = "10.0.0.0/26"
  
  # Public IP Configuration
  public_ip_count = 1  # Can be 1-100 for scaling
  
  # Firewall Policy Rules
  firewall_policy_rules = {
    network_rules = [
      {
        name     = "allow-internal-dns"
        priority = 100
        action   = "Allow"
        rules = [
          {
            name                  = "dns-rule"
            protocols             = ["UDP"]
            source_addresses      = ["10.0.0.0/16"]
            destination_addresses = ["168.63.129.16"]
            destination_ports     = ["53"]
          }
        ]
      }
    ]
    application_rules = [
      {
        name     = "allow-web-traffic"
        priority = 200
        action   = "Allow"
        rules = [
          {
            name              = "allow-microsoft"
            source_addresses  = ["10.0.0.0/16"]
            destination_fqdns = ["*.microsoft.com", "*.azure.com"]
            protocols = [
              {
                type = "Https"
                port = 443
              }
            ]
          }
        ]
      }
    ]
    nat_rules = [
      {
        name     = "inbound-nat"
        priority = 300
        action   = "Dnat"
        rules = [
          {
            name                  = "ssh-nat"
            protocols             = ["TCP"]
            source_addresses      = ["*"]
            destination_address   = "PUBLIC_IP"  # Replaced at runtime
            destination_ports     = ["2222"]
            translated_address    = "10.0.1.10"
            translated_port       = "22"
          }
        ]
      }
    ]
  }
  
  # DNS Configuration
  enable_dns_proxy = true
  dns_servers      = []  # Empty for Azure DNS
  
  # Threat Intelligence
  threat_intel_mode = "Alert"  # Alert, Deny, or Off
  
  # Premium Features (if sku_tier = "Premium")
  enable_tls_inspection = false
  idps_mode            = "Alert"  # Alert, Deny, or Off
  
  # Availability Zones
  availability_zones = ["1", "2", "3"]
  
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
- `firewall_subnet_id` - ID of the AzureFirewallSubnet

### Optional Variables

- `instance_number` - Instance number for naming (default: 1)
- `sku_tier` - Firewall SKU tier (default: "Standard")
  - Options: Standard, Premium
- `sku_name` - Firewall SKU name (default: "AZFW_VNet")
  - Options: AZFW_VNet, AZFW_Hub
- `public_ip_count` - Number of public IPs (default: 1, max: 100)
- `firewall_policy_rules` - Map of firewall policy rules
- `enable_dns_proxy` - Enable DNS proxy (default: true)
- `dns_servers` - List of custom DNS servers (default: [])
- `threat_intel_mode` - Threat intelligence mode (default: "Alert")
  - Options: Off, Alert, Deny
- `enable_tls_inspection` - Enable TLS inspection (Premium only, default: false)
- `idps_mode` - IDPS mode (Premium only, default: "Alert")
  - Options: Off, Alert, Deny
- `enable_forced_tunneling` - Enable forced tunneling (default: false)
- `availability_zones` - Availability zones (default: null)
- `tags` - Resource tags

## Outputs

- `firewall_id` - Azure Firewall resource ID
- `firewall_name` - Azure Firewall name
- `firewall_private_ip` - Firewall private IP address
- `firewall_public_ips` - List of firewall public IP addresses
- `firewall_policy_id` - Firewall Policy resource ID
- `firewall_policy_name` - Firewall Policy name

## Resource Naming

Resources created by this module follow the naming convention:

- Azure Firewall: `afw-{customer}-{env}-{region}-{instance}`
- Firewall Policy: `afwp-{customer}-{env}-{region}-{instance}`
- Public IP: `pip-afw-{customer}-{env}-{region}-{instance}`

## SKU Comparison

| Feature | Standard | Premium |
|---------|----------|---------|
| **Throughput** | 30 Gbps | 100 Gbps |
| **Network/Application Rules** | Yes | Yes |
| **NAT Rules** | Yes | Yes |
| **Threat Intelligence** | Yes | Yes |
| **DNS Proxy** | Yes | Yes |
| **TLS Inspection** | No | Yes |
| **IDPS** | No | Yes |
| **URL Filtering** | No | Yes |
| **Web Categories** | No | Yes |
| **Availability Zones** | Yes | Yes |
| **Use Case** | Basic filtering | Advanced security |

## Firewall Policy Rules

### Network Rules
Control traffic based on IP addresses, ports, and protocols.

```hcl
network_rules = [
  {
    name     = "allow-internal"
    priority = 100
    action   = "Allow"
    rules = [
      {
        name                  = "sql-traffic"
        protocols             = ["TCP"]
        source_addresses      = ["10.0.1.0/24"]
        destination_addresses = ["10.0.2.0/24"]
        destination_ports     = ["1433"]
      }
    ]
  }
]
```

### Application Rules
Control traffic based on FQDNs and URLs.

```hcl
application_rules = [
  {
    name     = "allow-azure-services"
    priority = 200
    action   = "Allow"
    rules = [
      {
        name              = "azure-apis"
        source_addresses  = ["10.0.0.0/16"]
        destination_fqdns = ["*.azure.com", "*.microsoft.com"]
        protocols = [
          {
            type = "Https"
            port = 443
          }
        ]
      }
    ]
  }
]
```

### NAT Rules (DNAT)
Translate public IP and port to internal resources.

```hcl
nat_rules = [
  {
    name     = "web-nat"
    priority = 300
    action   = "Dnat"
    rules = [
      {
        name                  = "http-nat"
        protocols             = ["TCP"]
        source_addresses      = ["*"]
        destination_address   = "PUBLIC_IP"
        destination_ports     = ["80"]
        translated_address    = "10.0.1.10"
        translated_port       = "80"
      }
    ]
  }
]
```

## Common Use Cases

### Hub-and-Spoke Network
```
Internet
    ↓
Azure Firewall (Hub VNet)
    ↓
Route Tables → Spoke VNets
    ↓
Workloads
```

### Outbound Internet Filtering
- Control which websites/services workloads can access
- Block malicious domains via threat intelligence
- Log all outbound connections

### Inbound NAT
- Expose internal services to internet
- Port translation and IP hiding
- Centralized entry point

### East-West Traffic
- Control traffic between VNets
- Micro-segmentation
- Zero-trust architecture

## Security Considerations

### Network Design
- Deploy in dedicated AzureFirewallSubnet (minimum /26)
- Use forced tunneling if routing through on-premises firewall
- Implement least-privilege rule sets
- Use Azure Firewall Manager for multi-firewall scenarios

### Rule Best Practices
- Order rules by priority (lower number = higher priority)
- Use specific source/destination addresses when possible
- Avoid using "Any" source for production rules
- Use FQDN filtering over IP addresses when possible
- Enable threat intelligence in "Deny" mode for production

### Premium Features
- Enable TLS inspection for encrypted traffic visibility
- Use IDPS in "Deny" mode to block threats
- Regularly review IDPS signatures
- Use URL filtering for granular web access control

### Monitoring
- Enable diagnostic logs for all rule collections
- Send logs to Log Analytics workspace
- Set up alerts for denied traffic spikes
- Monitor firewall health metrics
- Review threat intelligence hits regularly

## Dependencies

- Requires virtual network with AzureFirewallSubnet
- AzureFirewallSubnet must be at least /26 (64 addresses)
- Subnet must be named exactly "AzureFirewallSubnet"
- Public IP(s) for firewall frontend
- Optional: Management subnet for forced tunneling

## Routing Configuration

After deploying firewall, configure route tables:

```hcl
# Route table for spoke VNets
resource "azurerm_route_table" "spoke_rt" {
  name                = "rt-spoke"
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name                   = "default-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = module.azure_firewall.firewall_private_ip
  }
}
```

## Cost Considerations

**Standard Tier:**
- Deployment: ~$1.25/hour (~$912/month)
- Data Processed: $0.016 per GB

**Premium Tier:**
- Deployment: ~$1.75/hour (~$1,277/month)
- Data Processed: $0.016 per GB

**Additional Costs:**
- Public IP addresses: ~$3.65/month each
- Firewall Manager: ~$0.033/hour per policy
- Egress data charges apply

**Cost Optimization:**
- Use single firewall for multiple VNets (hub-spoke)
- Stop/deallocate firewall in dev environments when not needed
- Use Standard tier unless Premium features required
- Monitor data processed for unexpected traffic

## High Availability

### Availability Zones
Deploy across availability zones for 99.99% SLA:
```hcl
availability_zones = ["1", "2", "3"]
```

### Multiple Public IPs
Scale outbound connections:
```hcl
public_ip_count = 2  # Up to 100
```

### Forced Tunneling
Route management traffic separately:
```hcl
enable_forced_tunneling = true
# Requires separate management subnet and public IP
```

## Integration with Other Services

### Azure Firewall Manager
- Centralized management for multiple firewalls
- Global policies with local overrides
- Secured virtual hub (vWAN) integration

### Azure DDoS Protection
- Combine with DDoS Standard for enhanced protection
- Firewall handles application-layer filtering
- DDoS handles network-layer attacks

### Azure Monitor
- Diagnostic logs for rule hits
- Metrics for throughput and health
- Alerts for anomalies

### Azure Sentinel
- SIEM integration for security analytics
- Automated threat response
- Advanced hunting queries

## Limitations

- Maximum 100 public IP addresses per firewall
- Maximum throughput: 30 Gbps (Standard), 100 Gbps (Premium)
- Maximum concurrent connections: 250,000 per public IP
- Firewall subnet must be /26 or larger
- Cannot modify firewall subnet after creation
- TLS inspection only available in Premium tier
- IDPS only available in Premium tier

## Migration Considerations

### From Network Virtual Appliances (NVA)
1. Deploy Azure Firewall in parallel
2. Migrate rules incrementally
3. Update route tables
4. Test thoroughly before cutover
5. Decommission NVA

### Standard to Premium Upgrade
1. Upgrade requires downtime
2. Backup firewall policy
3. Stop traffic routing through firewall
4. Perform upgrade
5. Validate and restore traffic

## Troubleshooting

### Firewall Not Routing Traffic
- Verify route tables point to firewall private IP
- Check firewall rules allow traffic
- Ensure NSGs don't block traffic
- Verify DNS resolution

### High Latency
- Check firewall metrics for saturation
- Review rule complexity
- Consider adding more public IPs
- Evaluate Premium tier for higher throughput

### Rules Not Working
- Verify rule priority order
- Check source/destination addresses
- Enable diagnostic logs
- Review threat intelligence hits

### TLS Inspection Issues (Premium)
- Verify certificate chain
- Check client trust of CA certificate
- Review decrypted traffic logs
- Ensure compatible protocols

## Best Practices

✅ **Design**
- Use hub-spoke topology for multiple VNets
- Deploy across availability zones for HA
- Size subnet appropriately (min /26, recommend /25)

✅ **Rules**
- Start with least-privilege approach
- Use application rules over network rules when possible
- Enable threat intelligence in Deny mode
- Document all rules with business justification

✅ **Monitoring**
- Enable diagnostic logs for all rule collections
- Set up alerts for denied traffic spikes
- Regular review of firewall metrics
- Monitor costs monthly

✅ **Security**
- Use Premium tier for production workloads requiring TLS inspection
- Enable IDPS in Deny mode
- Regular review and update of rule sets
- Implement defense-in-depth with NSGs

✅ **Operations**
- Use Firewall Manager for multi-firewall scenarios
- Automate rule deployment via IaC
- Test changes in non-production first
- Maintain runbook for common issues

## Notes

- Azure Firewall is a managed service (no VM management)
- Supports both IPv4 and IPv6
- Built-in high availability
- Automatic scaling based on traffic
- Integration with Azure Monitor for visibility
- No software updates required
- Consider Azure Firewall Premium for advanced security features
- Use with Azure Virtual WAN for global network architecture
