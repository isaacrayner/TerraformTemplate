# Log Analytics workspace

Creates one Azure Log Analytics workspace. Naming is owned by the calling root
and diagnostic settings are created separately with `diagnostic-setting`.

## Usage

```hcl
module "log_analytics" {
  source = "git::https://github.com/isaacrayner/TerraformTemplate.git//modules/log-analytics?ref=v1.0.0"

  name                = "log-contoso-prod-uks-001"
  location            = "uksouth"
  resource_group_name = module.resource_groups.names["main"]

  retention_in_days = 30
  daily_quota_gb    = 5

  tags = var.tags
}
```

Use a release tag or commit SHA in customer repositories. Replace `v1.0.0`
with a release that exists in this repository; do not point production callers
at `main`.

## Inputs

| Name | Type | Default | Description |
|---|---|---:|---|
| `name` | `string` | required | Exact workspace name (4-63 valid characters). |
| `location` | `string` | required | Azure region. |
| `resource_group_name` | `string` | required | Existing resource group name. |
| `sku` | `string` | `PerGB2018` | Workspace pricing SKU. |
| `retention_in_days` | `number` | `30` | Data retention, 30-730 days. |
| `daily_quota_gb` | `number` | `-1` | Daily ingestion cap; `-1` is unlimited. |
| `local_authentication_enabled` | `bool` | `true` | Allow shared-key authentication. |
| `internet_ingestion_enabled` | `bool` | `true` | Allow ingestion over the public endpoint. |
| `internet_query_enabled` | `bool` | `true` | Allow queries over the public endpoint. |
| `tags` | `map(string)` | `{}` | Resource tags. |

## Outputs

| Name | Sensitive | Description |
|---|---:|---|
| `workspace_id` | no | Azure resource ID used by diagnostic settings. |
| `workspace_name` | no | Workspace name. |
| `workspace_customer_id` | no | Workspace/customer GUID used by agents. |
| `primary_shared_key` | yes | Legacy agent shared key. |

The module intentionally does not install solutions, agents, data collection
rules, or diagnostic settings. Those resources have different lifecycles and
should be composed by the customer root.
