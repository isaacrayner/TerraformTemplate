# Azure Bastion Module

This module creates an Azure Bastion host for secure RDP/SSH access to VMs without public IPs.

## Resources Created

- Azure Bastion Host
- Public IP for Bastion
- Dedicated Bastion subnet (AzureBastionSubnet)

## Usage

```hcl
module "bastion" {
  source = "../../modules/azure-bastion"
  
  customer_short_name = "contoso"
  environment         = "prod"
  location            = "eastus"
  location_code       = "eus"
  
  resource_group_name = module.networking.resource_group_name
  subnet_id           = module.networking.subnet_ids["bastion"]
  
  sku = "Standard"  # Basic or Standard
  
  tags = var.tags
}
```

## Naming Convention

- Bastion Host: `bas-{customer}-{env}-{region}-{instance}`
- Public IP: `pip-bas-{customer}-{env}-{region}-{instance}`

## Requirements

- Dedicated subnet named **AzureBastionSubnet** (minimum /27)
- Public IP address
- NSG rules (automatically configured)

## Features

- Secure RDP/SSH without public IPs on VMs
- Connects through Azure Portal
- SSL encrypted
- No VPN or client software needed
- Protects against port scanning

## SKU Comparison

| Feature | Basic | Standard |
|---------|-------|----------|
| Concurrent sessions | 25 | 50 |
| Copy/paste | ✓ | ✓ |
| IP-based connection | ✗ | ✓ |
| Custom port | ✗ | ✓ |
| Shareable link | ✗ | ✓ |
