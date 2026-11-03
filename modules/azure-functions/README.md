# Linux Azure Functions

Creates one Linux Function App and, by default, an Elastic Premium plan. Supply
`service_plan_id` to reuse a compatible Linux plan.

```hcl
module "function" {
  source = "git::https://github.com/isaacrayner/TerraformTemplate.git//modules/azure-functions?ref=v1.0.0"

  name                = "func-worker-contoso-prod-uks-001"
  service_plan_name   = "asp-func-contoso-prod-uks-001"
  location            = "uksouth"
  resource_group_name = module.resource_groups.names["main"]

  storage_account_name       = module.storage.storage_account_name
  storage_account_access_key = module.storage.primary_access_key
  runtime = {
    name    = "node"
    version = "20"
  }

  application_insights_connection_string = module.application_insights.connection_string
  tags                                   = var.tags
}
```

Supported runtime names are `dotnet`, `dotnet-isolated`, `java`, `node`,
`powershell`, and `python`; the caller supplies a version supported in the
target Azure region. Public access defaults off and basic publishing
authentication is disabled. Storage keys and app settings remain sensitive in
Terraform state; use a protected remote backend and prefer Key Vault references
for application secrets.
