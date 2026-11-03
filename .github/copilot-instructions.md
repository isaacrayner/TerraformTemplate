# Instructions for this Terraform module catalog

This repository contains a reusable Azure module catalog plus a customer root
starter. Treat `CONVENTIONS.md`, `MODULES_INDEX.md`, `MODULE_RELEASES.md`, and
`IMPLEMENTATION_ROADMAP.md` as authoritative.

## Do not confuse candidates with modules

A directory is callable only when it contains all of:

- `main.tf`
- `variables.tf`
- `outputs.tf`
- `versions.tf`
- `README.md`

A README-only directory is a candidate design. Never add a source reference,
enable flag, output count, or documentation claim that implies it deploys.

## Module contract

- Use Terraform `>= 1.5.0` and AzureRM `~> 4.0` unless an accepted major
  version decision changes the catalog baseline.
- Accept exact resource names from the root. Do not rebuild customer,
  environment, region, and instance naming inside a child module.
- Accept an existing resource group name; do not create an incidental resource
  group inside a workload module.
- Accept common tags from the caller and merge only documented resource-specific
  tags.
- Mark credentials and secret outputs sensitive. Do not place secrets in
  examples, defaults, state backend files, or source control.
- Default public/network access deliberately and expose an override when Azure
  services and customer risk/cost requirements differ.
- Keep diagnostics, private endpoints, private DNS, and role assignments as
  composable modules when their lifecycle differs from the target resource.
- Add outputs for IDs needed by composition, diagnostics, private endpoints,
  and role assignments.

## Customer roots

Local sources such as `../../modules/networking` are only for validating
`deployments/_template` inside this catalog. Customer repositories must use an
immutable release tag or commit SHA, for example:

```hcl
source = "git::https://github.com/isaacrayner/TerraformTemplate.git//modules/networking?ref=v1.0.0"
```

Each customer/environment/region owns a separate backend key and state boundary.
Backend credentials and customer secrets are supplied by CI, not committed.

### Two subscriptions in `deployments/_template`

The starter root spans two subscriptions in one tenant:

- **Landing Zone** (`landing_zone_subscription_id`, default `azurerm` provider):
  shared resource group, hub VNet, shared Key Vault, Log Analytics, Front Door + WAF.
- **Compute** (`compute_subscription_id`, `azurerm.compute` alias): workload
  resource group, spoke VNet, storage, Key Vaults, SQL, apps, VMs, AVD, ACA.

Every module call or resource for a Compute workload sets
`providers = { azurerm = azurerm.compute }` (or `provider = azurerm.compute`),
including its `diagnostic-setting` call. Landing-zone calls use the default
provider. Hub and spoke are peered in `hub-spoke-peering.tf`; Azure-reserved
subnets (`GatewaySubnet`, `AzureFirewallSubnet`, `AzureBastionSubnet`) set the
subnet `name` override, and the networking module skips NSGs where Azure forbids them.

## Change workflow

1. Confirm the target is an implemented module or explicitly promote a
   candidate as part of the change.
2. Keep module boundaries narrow; compose dependencies in the customer root.
3. Update the module README and `MODULES_INDEX.md` status.
4. Run `./scripts/validate.sh`.
5. Test a representative plan in a non-production subscription before calling
   the module stable.
6. Document breaking contracts and state migration in release notes.

Do not propose applying infrastructure from this catalog CI. Catalog CI formats
and validates; customer pipelines authenticate, plan, obtain approval, and
apply from the customer repository.
