# Azure Front Door Module

This module creates Azure Front Door (Standard or Premium tier).

## Resources Created

- Azure Front Door Profile
- Front Door Endpoints
- Origin Groups and Origins
- Routes

## Usage

```hcl
module "front_door" {
  source = "../../modules/front-door"
  
  customer_short_name = "contoso"
  environment         = "prod"
  location_code       = "global"
  
  resource_group_name = module.networking.resource_group_name
  location            = "global"
  
  sku_name = "Premium_AzureFrontDoor"
  
  origins = [
    {
      name     = "eastus-origin"
      hostname = module.app_service_eastus.app_service_hostname
    }
  ]
  
  tags = var.tags
}
```

## Naming Convention

- Front Door: `fd-{customer}-{env}-global-{instance}`

## Features

- Standard or Premium tier
- WAF integration (Premium tier)
- Private Link support (Premium tier)
- Global load balancing
- CDN capabilities
