# Azure Cache for Redis Module

Creates an Azure Cache for Redis instance with TLS-only access and — matching
`sql-database` — **no public endpoint by default**. See `CONVENTIONS.md` #1
(naming) and #2 (network access).

## Usage — private (default)

```hcl
module "redis_cache" {
  source = "../../modules/redis-cache"

  name                = "redis-contoso-prod-uks-001"
  location            = var.location
  resource_group_name = module.resource_groups.names["data"]

  sku_name = "Standard"
  family   = "C"
  capacity = 1

  tags = local.default_tags
}

module "pe_redis" {
  source = "../../modules/private-endpoints"

  name                 = "pep-redis-contoso-prod-uks-001"
  resource_group_name  = module.resource_groups.names["data"]
  location             = var.location
  subnet_id            = module.networking.subnet_ids["privatelink"]
  target_resource_id   = module.redis_cache.redis_cache_id
  subresource_names    = ["redisCache"]
  private_dns_zone_ids = [module.dns_redis.zone_id]
}
```

## Usage — public + firewall (deliberate opt-out)

```hcl
module "redis_cache" {
  source = "../../modules/redis-cache"
  # ...

  public_network_access_enabled = true
  allowed_ip_ranges = [
    { name = "Office", start_ip = "203.0.113.0", end_ip = "203.0.113.255" }
  ]
}
```

## Required Variables

| Variable | Type | Description |
|---|---|---|
| `name` | string | Exact Redis Cache name. Compute in the root — see `CONVENTIONS.md` #1. |
| `location` | string | Azure region |
| `resource_group_name` | string | Resource group name |

## Optional Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `sku_name` | string | `"Standard"` | Basic, Standard, or Premium |
| `family` | string | `"C"` | `C` for Basic/Standard, `P` for Premium — must match `sku_name` |
| `capacity` | number | `1` | Family C: 0-6. Family P: 1-5 |
| `non_ssl_port_enabled` | bool | `false` | Leave off unless a legacy client needs port 6379 |
| `minimum_tls_version` | string | `"1.2"` | |
| `maxmemory_policy` | string | `"volatile-lru"` | Redis eviction policy |
| `public_network_access_enabled` | bool | **`false`** | See "Why this defaults false" below |
| `allowed_ip_ranges` | list(object) | `[]` | Only takes effect if `public_network_access_enabled = true` |
| `tags` | map(string) | `{}` | |

## Outputs

| Output | Description |
|---|---|
| `redis_cache_id` | Resource ID — feed to `private-endpoints`' `target_resource_id` |
| `redis_cache_name` | Cache name |
| `hostname` | Cache hostname |
| `ssl_port` | TLS port (6380) |
| `primary_access_key` | Access key (sensitive) |
| `primary_connection_string` | Connection string (sensitive) |

## Why `public_network_access_enabled` defaults false

Same shape as `sql-database`: `azurerm_redis_cache` has no deny-by-default
network ACL like Key Vault or Storage Account — it's either a public endpoint
gated by `allowed_ip_ranges` firewall rules, or a private-endpoint-only cache.
Per `CONVENTIONS.md` #2, the secure default wins unless the caller opts out
visibly.

## Premium-tier features not covered

VNet injection (the older, pre-Private-Link way of putting Premium caches
inside a subnet directly), clustering, data persistence, and geo-replication
are Premium-only `azurerm_redis_cache` arguments this module does not expose.
Add them as additional variables if a workload needs them rather than
defaulting every cache to Premium's cost.

## Status

Implemented 2026-08-17, following `CONVENTIONS.md` end to end (no earlier
`customer_short_name`-based interface existed for this module to migrate
from).
