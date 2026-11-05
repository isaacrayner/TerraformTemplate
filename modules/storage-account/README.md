# Storage Account Module

Creates an Azure Storage Account with HTTPS-only, TLS 1.2 minimum, blob
versioning + delete retention, and a deny-by-default network firewall — all
override-able. See `CONVENTIONS.md` #1 (naming) and #2 (network access).

## Usage

```hcl
module "storage_account" {
  source = "../../modules/storage-account"

  name                 = "stcontosoproduks001"
  location             = var.location
  resource_group_name  = module.resource_groups.names["network"]

  account_tier             = "Standard"
  account_replication_type = "LRS"
  blob_containers           = ["data", "backups", "logs"]

  network_access = {
    subnet_ids = [module.networking.subnet_ids["privatelink"]]
  }

  tags = local.default_tags
}
```

## Required Variables

| Variable | Type | Description |
|---|---|---|
| `name` | string | Exact storage account name (3-24 chars, lowercase alphanumeric, no hyphens). Compute in the root — see `CONVENTIONS.md` #1. |
| `location` | string | Azure region |
| `resource_group_name` | string | Resource group name |

## Optional Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `account_tier` | string | `"Standard"` | |
| `account_replication_type` | string | `"LRS"` | LRS, GRS, ZRS, GZRS, RAGRS, RAGZRS |
| `enable_https_only` | bool | `true` | |
| `min_tls_version` | string | `"TLS1_2"` | |
| `blob_containers` | list(string) | `[]` | Container names to create (all `private` access) |
| `network_access` | object | see below | `CONVENTIONS.md` #2 shape |
| `tags` | map(string) | `{}` | |

`network_access` defaults: `default_action = "Deny"`, `bypass = ["AzureServices"]`,
`ip_rules = []`, `subnet_ids = []`, `public_network_access_enabled = true`.

## Outputs

| Output | Description |
|---|---|
| `storage_account_id` | Storage Account resource ID |
| `storage_account_name` | Storage Account name |
| `primary_blob_endpoint` | Primary blob endpoint URL |
| `primary_access_key` | Primary access key (sensitive) |

## Security defaults

- HTTPS-only, TLS 1.2 minimum
- `allow_nested_items_to_be_public = false` (not configurable — there's no
  legitimate reason to allow anonymous blob access on a customer deployment)
- Blob versioning + soft delete on both blobs and containers
- Network firewall deny-by-default (`network_access`)

## Status

Production Ready. Uplifted 2026-08-14: added `network_access` (this module
previously had **no network firewall at all** — it deployed publicly
reachable) and switched to the `CONVENTIONS.md` naming pattern. Root code
written against the older `customer_short_name`/`environment`/`location_code`/
`instance_number`/`name_suffix` interface needs updating to pass `name` directly.
