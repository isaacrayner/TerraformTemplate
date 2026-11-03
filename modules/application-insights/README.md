# Application Insights

Creates one workspace-based Application Insights component. The Log Analytics
workspace remains a separate lifecycle and is supplied by resource ID.

```hcl
module "application_insights" {
  source = "git::https://github.com/isaacrayner/TerraformTemplate.git//modules/application-insights?ref=v1.0.0"

  name                = "appi-api-contoso-prod-uks-001"
  location            = "uksouth"
  resource_group_name = module.resource_groups.names["main"]
  workspace_id        = module.log_analytics.workspace_id
  application_type    = "web"
  daily_data_cap_in_gb = 5
  tags                 = var.tags
}
```

Important inputs are the exact `name`, `location`, `resource_group_name`, and
`workspace_id`. Optional controls cover application type, daily cap, retention,
sampling, IP masking, local authentication, and internet ingestion/query.

Outputs include `id`, `name`, `app_id`, and sensitive `connection_string` and
`instrumentation_key`. Prefer the connection string for new integrations.

Diagnostics for Application Insights itself, alerts, workbooks, and action
groups are intentionally outside this module.
