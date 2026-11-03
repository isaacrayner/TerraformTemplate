# Container Registry

Creates one Azure Container Registry with admin and anonymous access disabled,
a system-assigned identity, and private network access by default.

```hcl
module "container_registry" {
  source = "git::https://github.com/isaacrayner/TerraformTemplate.git//modules/container-registry?ref=v1.0.0"

  name                = "acrcontosoproduks001"
  location            = "uksouth"
  resource_group_name = module.resource_groups.names["main"]
  sku                 = "Premium"
  tags                = var.tags
}
```

`Premium` is the default because disabling public access, geo-replication,
zone redundancy, and export-policy controls are Premium capabilities. A lower
SKU requires public access and excludes those features.

Outputs are `id`, `name`, `login_server`, and the system identity
`principal_id`. Grant workloads `AcrPull` in the calling root. Create private
endpoints, DNS, diagnostics, and role assignments with the corresponding
composition modules.
