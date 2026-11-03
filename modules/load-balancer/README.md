# Azure Load Balancer Module

This module creates an Azure Load Balancer with backend pools, health probes, and load balancing rules.

## Resources Created

- Azure Load Balancer (Internal or Public)
- Backend Address Pool
- Health Probes
- Load Balancing Rules
- Public IP (for public load balancers)

## Usage

```hcl
module "load_balancer" {
  source = "../../modules/load-balancer"
  
  customer_short_name = "contoso"
  environment         = "prod"
  location            = "eastus"
  location_code       = "eus"
  
  resource_group_name = module.networking.resource_group_name
  
  type = "private"  # or "public"
  
  # For internal load balancer
  subnet_id           = module.networking.subnet_ids["vms"]
  private_ip_address  = "10.0.2.10"
  
  # Backend pool VMs will be added separately
  
  health_probes = [
    {
      name     = "http-probe"
      protocol = "Http"
      port     = 80
      path     = "/health"
    }
  ]
  
  load_balancing_rules = [
    {
      name                = "http-rule"
      protocol            = "Tcp"
      frontend_port       = 80
      backend_port        = 80
      health_probe_name   = "http-probe"
    }
  ]
  
  tags = var.tags
}
```

## Naming Convention

- Load Balancer: `lb-{customer}-{env}-{region}-{instance}`
- Public IP: `pip-lb-{customer}-{env}-{region}-{instance}`

## Features

- Internal or Public load balancers
- Multiple backend pools
- Health probes (HTTP/HTTPS/TCP)
- Load balancing rules
- NAT rules support
- Zone redundancy (for public LBs)
