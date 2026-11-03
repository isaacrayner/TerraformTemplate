# Staged implementation roadmap

The catalog contains both working Terraform modules and design candidates.
Only a directory with `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, a
self-contained README, and passing automated validation is an implemented
module. A README-only directory is a candidate and must never be called from a
customer root.

## Stage 1 — trustworthy foundation (implemented)

- Establish root-owned naming and consistent provider constraints.
- Separate implemented modules from README-only candidates in the catalog.
- Add reusable validation for every implemented module and the deployment root.
- Add GitHub Actions and valid Azure Pipelines validation entry points.
- Define immutable, semantically versioned consumption by customer repositories.
- Implement Log Analytics and wire diagnostics into the deployment template.

Exit gate: every implemented module and `deployments/_template` passes
`terraform fmt -check` and `terraform validate` in CI.

## Stage 2 — deployable Azure baseline (implemented)

Implement in this order because later modules depend on earlier ones:

1. `application-insights`
2. `container-registry`
3. `app-service`
4. `azure-functions`
5. `virtual-machine`

For each module: secure defaults, managed identity where supported, diagnostic
wiring example, validation, outputs needed for composition, and an upgrade-safe
README. Add one representative root composition for a web workload.

Completed with map-driven, empty-by-default root composition in
`deployments/_template` and `web-workload.tfvars.example`.

## Stage 3 — private application platform (implemented)

Implemented `redis-cache`, `cosmos-db`, `api-management`, `aks`, and
`container-instances` (2026-08-17) — each secure-by-default per
`CONVENTIONS.md` #2 except `api-management`, which documents why it deviates.
Every module validated (`init -backend=false` + `validate`) against the real
azurerm v4.81.0 provider schema, including both a minimal usage and each
module's more advanced usage (VNet-integrated APIM, multi-region MongoDB-API
Cosmos, AKS with an additional node pool, a multi-container ACI group with a
shared volume) — not just a visual read-through; see D54/D55-style gotchas
`CONVENTIONS.md` #5 warns about, one of which recurred here (`container-instances`'
`image_registry_credentials` needed `nonsensitive()` in its `for_each`, the
same fix `sql_databases` needed in `deployments/_template`).

Deliberately not done as part of this stage: proving private DNS/subresource
combinations against a real test subscription (no Azure access from this
session), and workload-specific example roots. Both remain open. Note that
only `redis-cache` and `cosmos-db` front through a classic private endpoint
(subresources `redisCache` and `Sql`/`MongoDB` — see the `private-endpoints`
module's README reference table); `api-management` and `aks` use their own
direct VNet-integration arguments instead (`subnet_id`/`virtual_network_type`,
`vnet_subnet_id`), and `container-instances` takes a subnet directly via
`subnet_ids` — none of the three go through `private-endpoints`.

## Stage 4 — advanced connectivity and edge

Implement `public-ip`, `load-balancer`, `application-gateway`, `front-door`,
`azure-bastion`, `vpn-gateway`, and `azure-firewall`. These modules require
explicit topology decisions; avoid a single module that tries to represent
every hub/spoke and routing pattern.

## Stage 5 — governance and release maturity

- Add policy-as-code and security scanning with an explicit baseline.
- Add native Terraform tests and representative Azure plans.
- Generate module documentation and publish signed release notes.
- Add deprecation windows and state migration examples for breaking releases.
- Promote modules individually from experimental to stable based on deployment
  evidence, not file presence.

## Definition of done for every module

- The resource boundary is narrow and composable.
- Names and tags come from the caller; secrets are sensitive outputs/inputs.
- Public access defaults are deliberate and documented.
- Inputs have useful validation without embedding one customer's policy.
- Outputs expose IDs needed for role assignments, diagnostics, and composition.
- `init -backend=false`, `validate`, formatting, and a non-production plan pass.
- The README contains one version-pinned usage example and a migration note for
  every breaking change.
