# Azure API Management Module

Creates an `azurerm_api_management` gateway with optional VNet integration.
See `CONVENTIONS.md` #1 (naming) and #2 (network access) — this module
deviates from #2's usual false-by-default in a documented way, see below.

## Usage — public gateway (default, Developer tier)

```hcl
module "api_management" {
  source = "../../modules/api-management"

  name                = "apim-contoso-dev-uks-001"
  location            = var.location
  resource_group_name = module.resource_groups.names["main"]

  publisher_name  = "Contoso Ltd"
  publisher_email = "api@contoso.com"

  tags = local.default_tags
}
```

## Usage — Premium, internal (fully private) gateway

```hcl
module "api_management" {
  source = "../../modules/api-management"

  name                = "apim-contoso-prod-uks-001"
  location            = var.location
  resource_group_name = module.resource_groups.names["main"]

  publisher_name  = "Contoso Ltd"
  publisher_email = "api@contoso.com"

  sku_name              = "Premium_1"
  virtual_network_type  = "Internal"
  subnet_id             = module.networking.subnet_ids["apim"]
  public_network_access_enabled = false
  availability_zones    = ["1", "2", "3"]
  identity_type          = "SystemAssigned"

  tags = local.default_tags
}
```

The `apim` subnet needs, at minimum, service endpoints for
`Microsoft.Storage`, `Microsoft.Sql`, `Microsoft.EventHub`, and
`Microsoft.KeyVault` — APIM's control plane reaches these regardless of
`virtual_network_type`.

## Required Variables

| Variable | Type | Description |
|---|---|---|
| `name` | string | Exact, globally-unique service name. Compute in the root — see `CONVENTIONS.md` #1. |
| `location` | string | Azure region |
| `resource_group_name` | string | Resource group name |
| `publisher_name` | string | Organization name (developer portal, notifications) |
| `publisher_email` | string | Notification email |

## Optional Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `sku_name` | string | `"Developer_1"` | `"{Tier}_{Capacity}"` — Consumption, Developer, Basic, Standard, Premium |
| `public_network_access_enabled` | bool | **`true`** | See "Why this defaults true" below |
| `virtual_network_type` | string | `"None"` | None, External, or Internal |
| `subnet_id` | string | `null` | Required when `virtual_network_type != "None"` |
| `identity_type` | string | `null` | SystemAssigned, UserAssigned, or both |
| `availability_zones` | list(string) | `[]` | Premium tier only |
| `min_api_version` | string | `null` | |
| `tags` | map(string) | `{}` | |

## Outputs

| Output | Description |
|---|---|
| `apim_id` | Resource ID |
| `apim_name` | Service name |
| `gateway_url` | API gateway URL |
| `portal_url` / `developer_portal_url` | Publisher and developer portal URLs |
| `management_api_url` | Management API URL |
| `public_ip_addresses` / `private_ip_addresses` | Depend on `virtual_network_type` |
| `principal_id` | Managed identity principal ID, `null` if `identity_type` is unset |

## Why `public_network_access_enabled` defaults true

Every other network-facing module in this catalog defaults to no public
endpoint (`CONVENTIONS.md` #2). API Management is the exception the
convention itself calls out: it is fundamentally a public-facing gateway
service, not a PaaS backend meant to sit behind a private endpoint. Setting
this false only makes sense on Premium with `virtual_network_type =
"Internal"`, where the gateway is deliberately VNet-only end to end —
combine both when that's the goal, as in the second usage example.

## VNet integration and zones are tier-gated at plan time

Microsoft restrict `virtual_network_type != "None"` to the Developer and
Premium tiers, and `availability_zones` to Premium only — this is
documented behavior, not something the `sku_name` schema itself validates.
Getting it wrong on `azurerm_api_management` fails deep into provisioning
(APIM deployments take 30-45+ minutes) rather than at plan time, so this
module enforces both as `precondition` blocks instead.

## Status

Implemented 2026-08-17, following `CONVENTIONS.md` end to end. Replaces an
earlier README-only draft that used the pre-uplift `customer_short_name`/
`environment`/`location_code` naming interface — that draft's Terraform was
never written, so there is no prior root code to migrate.
