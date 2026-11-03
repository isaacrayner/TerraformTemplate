# Module: front-door

Deploys **Azure Front Door Standard/Premium** with WAF, multiple origin groups, and per-endpoint routing. Uses the `azurerm_cdn_frontdoor_*` resource family (AFD v2 — not the legacy `azurerm_frontdoor_*`).

## What this module creates

| Resource | Count | Naming |
|---|---|---|
| Front Door Profile | 1 | `fd-{name_suffix}` |
| Endpoint | 1 per endpoint entry | `fde-{key}-{name_suffix}` |
| Origin Group | 1 per origin_groups entry | `og-{key}` |
| Origin | N (flattened from groups) | `{origin_key}` |
| Route | 1 per routes entry | `route-{key}` |
| WAF Policy | 0–1 | `waf{name_suffix without hyphens}` |
| Security Policy | 0–1 | `secpol-{name_suffix}` |

The resource group comes from the caller (`CONVENTIONS.md` #1). Front Door is global, so there is no `location` input.

## Inputs

| Name | Type | Notes |
|---|---|---|
| `name_suffix` | string | Compute in the root, e.g. `local.name_prefix` |
| `resource_group_name` | string | From the `resource-group` module |
| `sku_name` | string | `Standard_AzureFrontDoor` or `Premium_AzureFrontDoor` |
| `response_timeout_seconds` | number | |
| `endpoints` / `origin_groups` / `routes` | map(object) | See `variables.tf` |
| `enable_waf` / `waf_mode` | bool / string | |
| `waf_managed_rule_sets` | list(object) | Premium only. Each set takes `type`, `version`, optional `action` (default `Block`) and `overrides` |
| `waf_custom_rules` | list(object) | Standard and Premium |
| `tags` | map(string) | |

## Quick start

```hcl
module "front_door" {
  source = "../../modules/front-door"

  name_suffix         = local.name_prefix
  resource_group_name = local.resource_group_name
  sku_name            = "Premium_AzureFrontDoor"

  origin_groups = var.front_door_origin_groups
  routes        = var.front_door_routes

  enable_waf = true
  waf_mode   = "Prevention"

  tags = var.tags
}
```

## SKU selection

| Feature | Standard | Premium |
|---|---|---|
| CDN / acceleration | ✅ | ✅ |
| Custom WAF rules | ✅ | ✅ |
| Microsoft-managed rule sets (OWASP, Bot) | ❌ | ✅ |
| Private Link origins | ❌ | ✅ |
| Advanced security reports | ❌ | ✅ |

**Use Premium for production deployments with WAF managed rules.**

## ACA integration example

Point Front Door at ACA container app URLs — no VNet or Private Link required for public ACA:

```hcl
# in terraform.tfvars
front_door_sku_name = "Premium_AzureFrontDoor"

front_door_origin_groups = {
  frontend = {
    health_probe_path = "/"
    origins = {
      primary = {
        host_name = "ca-contoso-prod-eus-001-frontend.happyforest-12345.eastus.azurecontainerapps.io"
      }
    }
  }
  api = {
    health_probe_path = "/health"
    origins = {
      primary = {
        host_name = "ca-contoso-prod-eus-001-api.happyforest-12345.eastus.azurecontainerapps.io"
      }
    }
  }
}

front_door_routes = {
  api-route = {
    endpoint_key     = "default"
    origin_group_key = "api"
    patterns_to_match = ["/api/*"]
    forwarding_protocol = "HttpsOnly"
  }
  frontend-route = {
    endpoint_key     = "default"
    origin_group_key = "frontend"
    patterns_to_match = ["/*"]
  }
}
```

Note: If ACA is deployed in the same Terraform root, use `module.aca[0].container_app_urls["frontend"]` instead of hardcoded hostnames.

## Multi-region active/active example

Use priority + weight for failover between regions:

```hcl
front_door_origin_groups = {
  app = {
    origins = {
      eastus   = { host_name = "myapp-eus.azurewebsites.net", priority = 1, weight = 1000 }
      westus   = { host_name = "myapp-wus.azurewebsites.net", priority = 1, weight = 1000 }
      failover = { host_name = "myapp-neu.azurewebsites.net", priority = 2, weight = 500 }
    }
  }
}
```

## WAF — common custom rules

**Rate limiting** (1000 req/min per IP):
```hcl
waf_custom_rules = {
  RateLimit = {
    priority                       = 100
    rule_type                      = "RateLimitRule"
    action                         = "Block"
    rate_limit_threshold           = 1000
    rate_limit_duration_in_minutes = 1
    match_conditions = [{
      match_variable = "RemoteAddr"
      operator       = "IPMatch"
      match_values   = ["0.0.0.0/0"]
    }]
  }
}
```

**Geo-blocking:**
```hcl
waf_custom_rules = {
  GeoBlock = {
    priority  = 200
    rule_type = "MatchRule"
    action    = "Block"
    match_conditions = [{
      match_variable = "RemoteAddr"
      operator       = "GeoMatch"
      match_values   = ["CN", "RU", "KP", "IR"]
    }]
  }
}
```

**Disable a noisy managed rule** (e.g., rule 942440 in SQLi group):
```hcl
waf_managed_rule_sets = [
  {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    overrides = [{
      rule_group_name = "SQLI"
      rules = [{
        rule_id = "942440"
        enabled = false
        action  = "Log"
      }]
    }]
  },
  { type = "Microsoft_BotManagerRuleSet", version = "1.0", overrides = [] }
]
```

## WAF mode: Detection → Prevention workflow

1. Deploy with `waf_mode = "Detection"` first
2. Review WAF logs in Log Analytics / Azure Monitor for false positives
3. Add overrides for any legitimate traffic being flagged
4. Switch to `waf_mode = "Prevention"` once tuned

## Variable reference

See `variables.tf` for full descriptions and validation rules on all variables.
