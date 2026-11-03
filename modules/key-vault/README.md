# Key Vault Module

Creates an Azure Key Vault with RBAC authorization, soft delete, purge
protection, and a deny-by-default network ACL — the secure defaults, all
override-able. See `CONVENTIONS.md` #1 (naming) and #2 (network access) for
the rationale behind this module's interface.

## Usage

```hcl
module "key_vault" {
  source = "../../modules/key-vault"

  name                 = "kv-contoso-prod-uks-001"
  location             = var.location
  resource_group_name  = module.resource_groups.names["network"]
  tenant_id            = data.azurerm_client_config.current.tenant_id

  network_access = {
    subnet_ids = [module.networking.subnet_ids["privatelink"]]
  }

  tags = local.default_tags
}
```

Relax network access for a cost-sensitive dev/test customer (CONVENTIONS.md
#2's "deliberate, visible choice in tfvars" principle):

```hcl
  network_access = {
    default_action = "Allow"
  }
```

## Required Variables

| Variable | Type | Description |
|---|---|---|
| `name` | string | Exact Key Vault name (3-24 chars). Compute in the root — see `CONVENTIONS.md` #1. |
| `location` | string | Azure region |
| `resource_group_name` | string | Resource group name |
| `tenant_id` | string | Azure AD tenant ID |

## Optional Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `sku_name` | string | `"standard"` | `standard` or `premium` |
| `enable_rbac_authorization` | bool | `true` | Use RBAC instead of access policies |
| `enabled_for_disk_encryption` | bool | `true` | |
| `enabled_for_deployment` | bool | `false` | |
| `enabled_for_template_deployment` | bool | `false` | |
| `soft_delete_retention_days` | number | `90` | 7-90 |
| `purge_protection_enabled` | bool | `true` | |
| `network_access` | object | see below | CONVENTIONS.md #2 shape |
| `tags` | map(string) | `{}` | |

`network_access` defaults: `default_action = "Deny"`, `bypass = ["AzureServices"]`,
`ip_rules = []`, `subnet_ids = []`, `public_network_access_enabled = true`
(endpoint present, firewalled — not disabled; see CONVENTIONS.md #2 for why).

## Outputs

| Output | Description |
|---|---|
| `key_vault_id` | Key Vault resource ID |
| `key_vault_name` | Key Vault name |
| `key_vault_uri` | Key Vault URI |
| `key_vault_tenant_id` | Tenant ID |

## Gotcha

`azurerm_key_vault.network_acls.bypass` takes a single string (`"AzureServices"`
or `"None"`), unlike Storage Account's set(string) equivalent — this module
takes the first entry of `network_access.bypass` for you, so pass a
single-item list.

## Status

Production Ready. Uplifted 2026-08-14 to `CONVENTIONS.md`'s naming and
network-access pattern — if you have root code written against the older
`customer_short_name`/`environment`/`location_code`/`instance_number`/`name_suffix`
interface, it needs updating to pass `name` directly.
