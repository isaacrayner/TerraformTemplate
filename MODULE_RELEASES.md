# Module release and consumption policy

This repository is the reusable module catalog. Customer infrastructure lives
in separate repositories and consumes immutable releases from this catalog.
Do not copy module implementation into customer repositories and do not source
production modules from `main`.

## Source modules from a release

```hcl
module "networking" {
  source = "git::https://github.com/isaacrayner/TerraformTemplate.git//modules/networking?ref=v1.0.0"

  name                = "vnet-contoso-prod-uks-001"
  location            = "uksouth"
  resource_group_name = module.resource_groups.names["main"]
  vnet_address_space  = ["10.20.0.0/16"]
  subnets              = var.subnets
  tags                 = local.tags
}
```

For private repositories, use an SSH source URL and provide a read-only deploy
key to CI. A full commit SHA is also acceptable when a customer requires exact
provenance.

## Versioning

Release the catalog using semantic versions:

- Patch: fixes that do not change a module's input/output contract.
- Minor: additive, backward-compatible inputs, outputs, or modules.
- Major: removed/renamed inputs or outputs, changed defaults that alter
  infrastructure materially, or changes that require state migration.

Because this is a monorepo, a catalog tag versions every implemented module at
once. Keep each customer on an explicit tag, upgrade it through a pull request,
and review the resulting Terraform plan before merging.

## Release gate

Before creating a tag:

1. Run `./scripts/validate.sh`.
2. Confirm the deployment template validates.
3. Record user-visible changes and any migration steps in release notes.
4. Test at least one representative plan in a non-production Azure subscription.
5. Create an annotated `vMAJOR.MINOR.PATCH` tag only from protected `main`.

The module catalog does not own customer state, credentials, backend settings,
or environment-specific naming. Those remain in each customer repository.
