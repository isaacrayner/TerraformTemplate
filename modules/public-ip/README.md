# Public IP Module

This module creates Azure Public IP addresses for use with load balancers, VMs, and gateways.

## Resources Created

- Public IP Address
- Optional DNS label

## Usage

```hcl
module "public_ip" {
  source = "../../modules/public-ip"
  
  customer_short_name = "contoso"
  environment         = "prod"
  location            = "eastus"
  location_code       = "eus"
  
  resource_group_name = module.networking.resource_group_name
  
  purpose         = "lb"  # Used in naming: pip-lb-contoso-prod-eus-001
  allocation_type = "Static"
  sku             = "Standard"
  
  domain_name_label = "contoso-prod-lb"  # Creates contoso-prod-lb.eastus.cloudapp.azure.com
  
  tags = var.tags
}
```

## Naming Convention

- Public IP: `pip-{purpose}-{customer}-{env}-{region}-{instance}`
  - Examples:
    - `pip-lb-contoso-prod-eus-001` (for load balancer)
    - `pip-agw-contoso-prod-eus-001` (for app gateway)
    - `pip-vm-contoso-prod-eus-001` (for VM)

## Allocation Types

| Type | Description | Use Case |
|------|-------------|----------|
| Static | IP never changes | Production services |
| Dynamic | IP assigned on resource start | Dev/test |

## SKU Options

| SKU | Zone-redundant | Use With |
|-----|----------------|----------|
| Basic | No | Basic LB, VMs |
| Standard | Yes | Standard LB, App Gateway, Bastion |

## Features

- Static or dynamic allocation
- IPv4 and IPv6 support
- DNS name labels
- Zone redundancy (Standard SKU)
- DDoS protection integration
