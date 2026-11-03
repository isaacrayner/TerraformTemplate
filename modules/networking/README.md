# Networking Module

Creates a Virtual Network, subnets, and one NSG per subnet (default-deny
inbound; add real tiered rules per subnet at the root — this module ships a
placeholder, not a security design). Does **not** create its own resource
group — see `CONVENTIONS.md` #1.

## Usage

```hcl
module "resource_groups" {
  source = "../../modules/resource-group"
  resource_groups = {
    network = { name = "rg-network-contoso-prod-uks", location = "uksouth" }
  }
}

module "networking" {
  source = "../../modules/networking"

  name                 = "vnet-contoso-prod-uks-001"
  location             = "uksouth"
  resource_group_name  = module.resource_groups.names["network"]

  vnet_address_space = ["10.0.0.0/16"]

  subnets = {
    gateway    = { address_prefix = "10.0.0.0/24" }
    appservice = { address_prefix = "10.0.1.0/24" }
    vms        = { address_prefix = "10.0.2.0/24" }
    data       = { address_prefix = "10.0.3.0/24" }
    mgmt       = { address_prefix = "10.0.255.0/24" }
  }

  tags = local.default_tags
}
```

## Required Variables

| Variable | Type | Description |
|---|---|---|
| `name` | string | Exact VNet name. Compute in the root — see `CONVENTIONS.md` #1. Also used as the naming suffix for subnets/NSGs. |
| `location` | string | Azure region |
| `resource_group_name` | string | From the `resource-group` module |
| `vnet_address_space` | list(string) | e.g. `["10.0.0.0/16"]` |
| `subnets` | map(object) | Key = logical subnet name; `address_prefix` required, `service_endpoints` optional |

## Optional Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `tags` | map(string) | `{}` | |

## Outputs

| Output | Description |
|---|---|
| `vnet_id` / `vnet_name` / `vnet_address_space` | |
| `subnet_ids` / `subnet_names` | Map keyed by the logical subnet name you supplied |
| `nsg_ids` / `nsg_names` | Map keyed by the logical subnet name |

## Naming

- Subnet: `snet-{key}-{name}` — e.g. `snet-data-vnet-contoso-prod-uks-001`
- NSG: `nsg-{key}-{name}`

## Gotcha

Every subnet gets an NSG with a single `DenyAllInbound` rule at priority 4096.
That's a placeholder, not real segmentation — Azure denies unmatched traffic
by default anyway, so this rule is close to a no-op. Add real per-subnet
`azurerm_network_security_rule` resources at the root for actual tiered
access control (see RADical's `modules/spoke-landing-zone` for a worked
example of a five-tier NSG design). Not fixed here — flagged as a further
follow-up beyond this uplift pass.

## Status

Production Ready. Uplifted 2026-08-14: this module previously created its own
resource group internally (an architecture smell — it duplicated naming logic
the caller already owns, and made the module impossible to compose into an
existing RG) and derived its own name from `customer_short_name`/`environment`/
`location_code`/`instance_number`. Both removed in favor of explicit `name`
and `resource_group_name` inputs. A pre-existing, unrelated defect was also
fixed in the same pass: `dynamic "service_endpoints"` is not valid HCL for
`azurerm_subnet` (`service_endpoints` is a plain attribute) — this module had
apparently never been run through `terraform validate` before.
