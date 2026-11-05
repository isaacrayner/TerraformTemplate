# Linux App Service

Creates one Linux Web App and, by default, one Linux App Service Plan. Supply
`service_plan_id` to reuse a shared plan instead.

```hcl
module "web" {
  source = "git::https://github.com/isaacrayner/TerraformTemplate.git//modules/app-service?ref=v1.0.0"

  name                = "app-api-contoso-prod-uks-001"
  service_plan_name   = "asp-api-contoso-prod-uks-001"
  location            = "uksouth"
  resource_group_name = module.resource_groups.names["main"]

  application_stack = {
    node_version = "20-lts"
  }

  application_insights_connection_string = module.application_insights.connection_string
  tags                                   = var.tags
}
```

The app is HTTPS-only, disables FTP/WebDeploy basic authentication, uses TLS
1.2+, and has a system-assigned identity. Its public endpoint defaults off;
compose a private endpoint and DNS in the customer root, or explicitly enable
public access.

For private container images, set the Docker stack fields and
`container_registry_use_managed_identity = true`, then grant this module's
`principal_id` the `AcrPull` role on the registry. App settings are sensitive
because Terraform state may contain their values; prefer Key Vault references.
