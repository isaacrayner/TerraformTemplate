# Conventions

Read this once per deployment instead of re-deriving these decisions from the
module source each time. If a module's comments or README seem to contradict
this file, this file wins — fix the module, don't re-litigate the decision.

Adapted from the RADical Systems Azure Terraform build (`C:\Code\RADical-Azure-Terraform`),
which is the reference implementation for "what good looks like" on this template.

## 0. Provider version: azurerm ~> 4.0

Every module and the deployment root pin `azurerm ~> 4.0`, matching RADical.
All modules in this template validate clean against it (v4.81.0 at last
check). One consequence worth knowing: `azurerm_monitor_diagnostic_setting`'s
metrics block is `enabled_metric` on v4.x — it was `metric` on v3.x. If you
ever see a module using `metric { category = "AllMetrics" }`, that's stale
v3-era code, not a valid alternative.

## 1. Naming lives in the root, not in modules

Modules take an explicit `name` (or a `resource_groups`/similar map with exact
names) as input. They do not derive names from `customer_short_name` +
`environment` + `location_code` + `instance_number` internally.

**Why:** the naming formula would otherwise be duplicated in every module —
25+ copies of the same string interpolation, each one a place the convention
can drift or need editing when it changes. Compute names once, in the
deploying root's `locals`, and pass plain strings into modules. This is the
rule that let `resource-group`, `diagnostic-setting`, `private-endpoints` and
`private-dns-zone` get ported from RADical with zero changes — they never
knew about customer/environment naming to begin with.

**Status:** `key-vault`, `networking`, `storage-account`, `sql-database` (the
4 modules that predate this file) were uplifted to this pattern 2026-08-14.
`networking` also stopped creating its own resource group internally in the
same pass — take `resource_group_name` from the `resource-group` module
instead. `deployments/_template` computes `name_prefix` once in `locals.tf`
and is the reference example of this pattern end to end.

Customer repositories consume these modules from immutable Git tags or commit
SHAs; see `MODULE_RELEASES.md`. Local `../../modules/...` paths are reserved for
developing and validating the example root in this catalog repository.

Suggested root naming pattern (unchanged from those 4 modules, just moved to
the caller):

```hcl
locals {
  name_prefix = "${var.customer_short_name}-${var.environment}-${var.location_code}-${format("%03d", var.instance_number)}"
}
# e.g. "kv-${local.name_prefix}", "pep-blob-${local.name_prefix}"
```

## 2. Network access is a variable, not a mandate

Every module that fronts a PaaS service should expose network access as an
override-able input, defaulting to the secure position (deny public access,
require a private endpoint) but easy to relax per customer/budget.

**Why:** RADical's own build documents this explicitly (decision D28): *"where
a meaningful cost saving is available without a significant security impact,
take it; otherwise default to Microsoft best practice."* Not every customer
on this template needs or can afford full private-endpoint coverage — but the
default should always be the secure one, so relaxing it is a deliberate,
visible choice in tfvars, not silence.

**Standard shape** (extend to any module fronting a PaaS resource — Key
Vault, Storage Account, SQL Database, Cosmos DB, Redis, etc.):

```hcl
variable "network_access" {
  description = "Network access policy for this resource."
  type = object({
    default_action                = optional(string, "Deny") # Allow | Deny
    bypass                        = optional(list(string), ["AzureServices"])
    ip_rules                      = optional(list(string), [])
    subnet_ids                    = optional(list(string), [])
    public_network_access_enabled = optional(bool, true)
  })
  default = {}
}
```

Every field here is consumed directly by the resource — no inert flags.
`public_network_access_enabled` defaults `true` deliberately: RADical's own
Key Vault (D-IMPL-7/D56) keeps the public endpoint *present* but firewalled
(`default_action = Deny` + `bypass = AzureServices`), rather than disabling it
outright, because some trusted-service integrations need that endpoint to
exist. Set it `false` only for resources that must be fully private (e.g. an
ACA environment, D20). Whether a private endpoint actually gets created is a
separate, root-level decision — call the `private-endpoints` module or don't;
no module flag drives that, because the module doesn't create the PE itself.

**Status:** `key-vault`, `storage-account`, `sql-database` uplifted to this
pattern 2026-08-14 (`sql-database` uses a plain `public_network_access_enabled`
variable instead of the full object — `azurerm_mssql_server` has no
`network_rules`/`network_acls`-equivalent block; its IP allow-listing is the
separate `azurerm_mssql_firewall_rule` resource the module already has).

## 3. Every module ships a self-sufficient README

A future session should be able to call a module correctly from its README
alone — an inputs table and one copy-paste `module "x" { ... }` block — and
never need to open `main.tf`/`variables.tf` to figure out usage. That's the
whole point of maintaining this template: it's cheaper to read a short README
than to reverse-engineer HCL, every single time you start a new deployment.

Keep README content specific to the module. Generic Azure background
(what is a private endpoint, why use one), cost estimates (go stale fast —
check current pricing instead), and step-by-step CLI troubleshooting belong
in Microsoft's docs, not repeated in 25 module READMEs. Link out instead of
inlining.

## 4. Diagnostics are not optional, and not Phase 3

Every resource this template creates that can emit logs/metrics should get a
`diagnostic-setting` call in the same root that creates it, targeting a
`log-analytics` workspace. RADical treats this as day-one, not hardening —
follow the same rule here.

`deployments/_template` implements this as a conditional pattern: a root
`log_analytics_workspace_id` variable can point at a shared hub workspace. If
it is unset and `enable_log_analytics` is true, the root creates a workspace
with the implemented `log-analytics` module. The resulting local value gates
every `diagnostic-setting` call (`core.tf`'s NSGs, `key-vaults.tf`,
`storage.tf`, `databases.tf`).

## 5. Validate before calling a module done — and validate the whole root, not just each module

`terraform fmt -recursive` and, against a scratch root with
`terraform init -backend=false`, `terraform validate` — every time a module
is added or changed. RADical's decision log (D54/D55) records two real
provider-schema defects that passed a visual read-through and were only
caught by actually running `validate`. Don't skip this step to save time; it
costs far more time later, in a future session that inherits the bug.

Validating each module in isolation is not sufficient — validate the
deployment root that composes them too. When `deployments/_template` was
uplifted to the pattern in this file (2026-08-14), each of the 4 uplifted
modules validated cleanly on its own, but the root itself failed on two
defects that had apparently been there since the template was written:
`var.sql_databases` is `sensitive = true` (it carries admin passwords), and a
sensitive-marked expression can't be used as a `for_each` argument or flow
into a non-sensitive output — the exact gotcha RADical's D55 documents,
independently rediscovered here. Fix: `nonsensitive(var.sql_databases)` in
`for_each`, and `nonsensitive(length(var.sql_databases))` in the
`deployment_info` output (only the count leaves the sensitive boundary, not
any credential). See `databases.tf`/`outputs.tf` for the fixed pattern —
copy it if you add another sensitive map variable with a `for_each` over it.
