# Azure Cosmos DB Module

Creates an `azurerm_cosmosdb_account` (the RU-based, multi-model account —
SQL/Core API by default, MongoDB API via `kind = "MongoDB"`, Cassandra/
Gremlin/Table via `capabilities` on the SQL kind). **No public endpoint by
default**, matching `sql-database`/`redis-cache` — see `CONVENTIONS.md` #1
(naming) and #2 (network access).

> For a vCore MongoDB-compatible service instead of the classic RU-based
> account, use `azurerm_mongo_cluster` (Azure Cosmos DB for MongoDB vCore /
> DocumentDB) — a different resource, not covered by this module. RADical's
> own build (`C:\Code\RADical-Azure-Terraform`, decision D42) chose that path
> over this one for its own reasons; pick per workload.

## Usage — single region, private (default)

```hcl
module "cosmos_db" {
  source = "../../modules/cosmos-db"

  name                 = "cosmos-contoso-prod-uks-001"
  location             = var.location
  resource_group_name  = module.resource_groups.names["data"]

  geo_locations = [
    { location = var.location, failover_priority = 0 }
  ]

  tags = local.default_tags
}

module "pe_cosmos" {
  source = "../../modules/private-endpoints"

  name                 = "pep-cosmos-contoso-prod-uks-001"
  resource_group_name  = module.resource_groups.names["data"]
  location             = var.location
  subnet_id            = module.networking.subnet_ids["privatelink"]
  target_resource_id   = module.cosmos_db.cosmosdb_account_id
  subresource_names    = ["Sql"] # or ["MongoDB"] for kind = "MongoDB"
  private_dns_zone_ids = [module.dns_cosmos.zone_id]
}
```

## Usage — MongoDB API, multi-region, public + allow-list

```hcl
module "cosmos_db_mongo" {
  source = "../../modules/cosmos-db"
  # ...

  kind         = "MongoDB"
  capabilities = ["EnableMongo"]

  consistency_level = "BoundedStaleness"
  max_interval_in_seconds = 300
  max_staleness_prefix    = 100000

  enable_automatic_failover = true
  geo_locations = [
    { location = "uksouth", failover_priority = 0, zone_redundant = true },
    { location = "ukwest", failover_priority = 1, zone_redundant = true },
  ]

  public_network_access_enabled = true
  ip_range_filter                = ["203.0.113.0/24"]

  backup_type = "Continuous"
}
```

## Required Variables

| Variable | Type | Description |
|---|---|---|
| `name` | string | Exact, globally-unique account name. Compute in the root — see `CONVENTIONS.md` #1. |
| `location` | string | Azure region for the account and its primary `geo_location` |
| `resource_group_name` | string | Resource group name |
| `geo_locations` | list(object) | At least one entry; exactly one with `failover_priority = 0` |

## Optional Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `kind` | string | `"GlobalDocumentDB"` | SQL/Core API, or `"MongoDB"` |
| `capabilities` | list(string) | `[]` | e.g. `["EnableMongo"]`, `["EnableCassandra"]`, `["EnableServerless"]` |
| `consistency_level` | string | `"Session"` | Eventual, ConsistentPrefix, Session, BoundedStaleness, Strong |
| `max_interval_in_seconds` / `max_staleness_prefix` | number | `null` | Required together when `consistency_level = "BoundedStaleness"` |
| `enable_automatic_failover` | bool | `false` | |
| `enable_multiple_write_locations` | bool | `false` | |
| `enable_free_tier` | bool | `false` | One per subscription |
| `public_network_access_enabled` | bool | **`false`** | See "Why this defaults false" below |
| `ip_range_filter` | list(string) | `[]` | Only takes effect if `public_network_access_enabled = true` |
| `virtual_network_subnet_ids` | list(string) | `[]` | VNet service-endpoint rule — not a private endpoint, see note below |
| `network_acl_bypass_for_azure_services` | bool | `true` | CONVENTIONS.md #2's AzureServices bypass |
| `backup_type` | string | `"Periodic"` | Periodic or Continuous (point-in-time restore) |
| `backup_interval_in_minutes` / `backup_retention_in_hours` / `backup_storage_redundancy` | — | `240` / `720` / `"Geo"` | Periodic only |
| `continuous_tier` | string | `"Continuous30Days"` | Continuous only |
| `tags` | map(string) | `{}` | |

## Outputs

| Output | Description |
|---|---|
| `cosmosdb_account_id` | Resource ID — feed to `private-endpoints`' `target_resource_id` |
| `cosmosdb_account_name` | Account name |
| `endpoint` | Account endpoint URL |
| `read_endpoints` / `write_endpoints` | Ordered region endpoint lists |
| `primary_key` | Primary master key (sensitive) |
| `primary_sql_connection_string` | SQL API connection string (sensitive) |
| `primary_mongodb_connection_string` | MongoDB API connection string, only populated when `kind = "MongoDB"` (sensitive) |

## Why `public_network_access_enabled` defaults false

Same reasoning as `sql-database`/`redis-cache`: `azurerm_cosmosdb_account` has
no deny-by-default network ACL — it's an allow-list (`ip_range_filter`,
`virtual_network_subnet_ids`) on a public endpoint, or no public endpoint at
all. Per `CONVENTIONS.md` #2, the secure default wins unless the caller opts
out visibly.

`virtual_network_subnet_ids` is a **VNet service-endpoint** rule
(`Microsoft.AzureCosmosDB` on the subnet), separate from a private endpoint —
it still uses the account's public IP under the hood, just restricted to
traffic that already originates inside the named subnet. For a fully private
path with no public IP involved, leave this empty and call the
`private-endpoints` module instead (see the usage example above).

## Status

Implemented 2026-08-17, following `CONVENTIONS.md` end to end. Replaces an
earlier README-only draft that used the pre-uplift `customer_short_name`/
`environment`/`location_code` naming interface — that draft's Terraform was
never written, so there is no prior root code to migrate.
