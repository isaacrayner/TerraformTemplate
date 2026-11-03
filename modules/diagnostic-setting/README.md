# diagnostic-setting

Ships one resource's logs/metrics to a Log Analytics workspace. One call per
resource you want monitored — call it once per NSG, once per Key Vault, etc.
(`for_each` it at the call site if you have many of the same type).

## Usage

```hcl
module "diag_key_vault" {
  source = "../../modules/diagnostic-setting"

  name                       = "diag-${module.key_vault.key_vault_name}"
  target_resource_id         = module.key_vault.key_vault_id
  log_analytics_workspace_id = module.log_analytics.workspace_id
}
```

Metrics-only or no-metrics resource (e.g. an NSG has no metrics):

```hcl
module "diag_nsg" {
  source = "../../modules/diagnostic-setting"

  name                       = "diag-nsg-web"
  target_resource_id         = module.networking.nsg_ids["web"]
  log_analytics_workspace_id = module.log_analytics.workspace_id
  metrics_enabled            = false
}
```

## Inputs

| Variable | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | string | yes | — | Diagnostic setting name |
| `target_resource_id` | string | yes | — | Resource being monitored |
| `log_analytics_workspace_id` | string | yes | — | Destination workspace |
| `log_category_groups` | list(string) | no | `["allLogs"]` | Use `[]` for metrics-only resources |
| `metrics_enabled` | bool | no | `true` | Ship `AllMetrics` |

## Outputs

| Output | Description |
|---|---|
| `id` | Diagnostic setting resource ID |

## Gotcha

`azurerm_monitor_diagnostic_setting` does not accept a `tags` argument — that's
an Azure API limitation, not an oversight in this module. Don't add one.

## Status

Production Ready — ported from the RADical Systems build (`modules/monitoring/diagnostic-setting`), unchanged.
