# Customer deployment starter

This root composes only modules that have Terraform implementation files and
pass the repository validation gate. Copy it into a customer repository, then
replace local module sources with version-pinned Git sources from
`MODULE_RELEASES.md`.

## Two subscriptions

The root deploys across two subscriptions in the same Entra ID tenant. The
identity running Terraform needs Contributor (or an equivalent custom role) on
both.

| Subscription | Provider | Holds |
|---|---|---|
| Landing Zone (`landing_zone_subscription_id`) | default `azurerm` | Shared resource group, hub VNet, shared Key Vault, Log Analytics, Front Door + WAF |
| Compute (`compute_subscription_id`) | `azurerm.compute` | Workload resource group, spoke VNet, everything in the baseline below, AVD, ACA |

Hub and spoke are peered in both directions (`hub-spoke-peering.tf`).

## Included baseline

- Resource group creation, or reuse of one existing compute resource group
- Hub and spoke VNets, subnets, and one NSG per subnet (none on `GatewaySubnet` / `AzureFirewallSubnet`)
- Multiple storage accounts and Key Vaults
- Multiple Azure SQL servers/databases
- Log Analytics, with support for a shared existing workspace
- Workspace-based Application Insights, Linux Web Apps, and Function Apps
- Container Registry with managed-identity workload pull assignments
- SSH-only Linux VMs
- Diagnostic settings for the implemented baseline resources
- Optional private endpoints and private DNS examples
- Optional Azure Virtual Desktop, Azure Container Apps, and Front Door + WAF,
  each off by default behind its `enable_*` flag

README-only candidate modules are deliberately absent. Setting a flag must
never silently do nothing.

## Start a customer deployment

```bash
cp -R deployments/_template ../contoso-infrastructure
cd ../contoso-infrastructure
cp terraform.tfvars.example terraform.tfvars
```

Then:

1. Change each `../../modules/...` source to a version-pinned Git source.
2. Configure a unique backend in `backend.tf`.
3. Replace the sample subscription IDs, credentials, address ranges, names, and
   tags in `terraform.tfvars`.
4. Keep credentials outside version control; use CI secret variables or an
   approved secret store.
5. Run `terraform init`, `terraform fmt -check`, `terraform validate`, and
   `terraform plan`.
6. Review the complete plan before applying in a non-production subscription.

For the representative web workload, apply the optional overlay during review:

```bash
terraform plan \
  -var-file=terraform.tfvars \
  -var-file=web-workload.tfvars.example
```

## File map

| File | Responsibility |
|---|---|
| `providers.tf` | Terraform/AzureRM constraints and provider configuration |
| `backend.tf` | Per-customer remote state configuration |
| `variables.tf` | Root input contract |
| `locals.tf` | Naming and effective shared-resource decisions |
| `landing-zone.tf` | Shared resource group, hub VNet, shared Key Vault (Landing Zone subscription) |
| `hub-spoke-peering.tf` | Hub-to-spoke and spoke-to-hub VNet peering |
| `core.tf` | Compute resource group, spoke VNet, and NSG diagnostics |
| `monitoring.tf` | Log Analytics workspace (Landing Zone subscription); Defender examples |
| `applications.tf` | Application Insights, Linux Web Apps, and Function Apps |
| `containers.tf` | Container registries, diagnostics, and AcrPull assignments |
| `compute.tf` | SSH-only Linux VMs |
| `storage.tf` | Storage accounts and diagnostics |
| `key-vaults.tf` | Key Vaults and diagnostics |
| `databases.tf` | Azure SQL and diagnostics |
| `private-connectivity.tf` | Opt-in private endpoint composition example |
| `avd.tf` | Azure Virtual Desktop host pools and session hosts (`enable_avd`) |
| `aca.tf` | Azure Container Apps environment and apps (`enable_aca`) |
| `front-door.tf` | Front Door + WAF (`enable_front_door`, Landing Zone subscription) |
| `outputs.tf` | Non-secret deployment contract |
| `terraform.tfvars.example` | Safe example values; copy but never commit secrets |
| `web-workload.tfvars.example` | Optional Stage 2 web workload overlay |

## Observability choice

The default creates one workspace, in the Landing Zone subscription's shared
resource group, with a finite example quota. It receives diagnostics from both
subscriptions:

```hcl
enable_log_analytics            = true
log_analytics_retention_in_days = 30
log_analytics_daily_quota_gb    = 5
```

To use a central workspace, set `log_analytics_workspace_id`. The root then
skips local workspace creation and sends diagnostics to the supplied ID. Set
`enable_log_analytics = false` with no existing ID only when the customer has
explicitly accepted that diagnostic settings will not be created.

## Isolation rules

- One backend key and state boundary per customer/environment/region.
- One customer repository must not read another customer's state directly.
- Customer-specific policy belongs in the customer root, not in shared modules.
- Upgrade module release tags through reviewed pull requests and inspect the
  resulting plan before merge.

The implementation sequence for additional workloads is in
`IMPLEMENTATION_ROADMAP.md`.
