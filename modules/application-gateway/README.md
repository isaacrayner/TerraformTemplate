# Application Gateway Module

This module creates an Azure Application Gateway for web application load balancing and WAF.

## Resources Created

- Azure Application Gateway (v2)
- Public IP for Application Gateway
- WAF Policy (optional)
- SSL certificates (if provided)

## Usage

```hcl
module "app_gateway" {
  source = "../../modules/application-gateway"
  
  customer_short_name = "contoso"
  environment         = "prod"
  location            = "eastus"
  location_code       = "eus"
  
  resource_group_name = module.networking.resource_group_name
  subnet_id           = module.networking.subnet_ids["gateway"]
  
  sku_name     = "WAF_v2"
  sku_tier     = "WAF_v2"
  sku_capacity = 2
  
  backend_pools = [
    {
      name  = "app-backend"
      fqdns = ["app-contoso-prod-eus-001.azurewebsites.net"]
    }
  ]
  
  enable_waf = true
  
  tags = var.tags
}
```

## Naming Convention

- Application Gateway: `agw-{customer}-{env}-{region}-{instance}`
- Public IP: `pip-agw-{customer}-{env}-{region}-{instance}`

## Features

- Layer 7 load balancing
- Web Application Firewall (WAF)
- SSL/TLS termination
- URL-based routing
- Multi-site hosting
- HTTP/2 support
- Autoscaling

## SKU Options

| SKU | Description | Use Case |
|-----|-------------|----------|
| Standard_v2 | Basic load balancing | Non-production |
| WAF_v2 | With WAF protection | Production web apps |
