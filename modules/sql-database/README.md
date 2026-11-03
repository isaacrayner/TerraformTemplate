# Azure SQL Database Module

Creates an Azure SQL Server + Database with TLS 1.2 minimum, Azure AD admin
support, threat detection, and — the significant change from earlier versions
of this module — **no public endpoint by default**. See `CONVENTIONS.md` #1
(naming) and #2 (network access).

## Usage — private (default)

```hcl
module "sql_database" {
  source = "../../modules/sql-database"

  name                 = "sql-contoso-prod-uks-001"
  location             = var.location
  resource_group_name  = module.resource_groups.names["network"]

  admin_username = "sqladmin"
  admin_password = data.azurerm_key_vault_secret.sql_password.value
  database_name  = "appdb"

  tags = local.default_tags
}

module "pe_sql" {
  source = "../../modules/private-endpoints"

  name                 = "pep-sql-contoso-prod-uks-001"
  resource_group_name  = module.resource_groups.names["network"]
  location             = var.location
  subnet_id            = module.networking.subnet_ids["privatelink"]
  target_resource_id   = module.sql_database.sql_server_id
  subresource_names    = ["sqlServer"]
  private_dns_zone_ids = [module.dns_sql.zone_id]
}
```

## Usage — public + firewall (deliberate opt-out, e.g. no PE budget)

```hcl
module "sql_database" {
  source = "../../modules/sql-database"
  # ...

  public_network_access_enabled = true
  allow_azure_services          = true
  allowed_ip_ranges = [
    { name = "Office", start_ip_address = "203.0.113.0", end_ip_address = "203.0.113.255" }
  ]
}
```

## Required Variables

| Variable | Type | Description |
|---|---|---|
| `name` | string | Exact SQL Server name. Compute in the root — see `CONVENTIONS.md` #1. |
| `location` | string | Azure region |
| `resource_group_name` | string | Resource group name |
| `admin_username` | string | SQL Server admin username |
| `admin_password` | string | SQL Server admin password (use Key Vault!) |
| `database_name` | string | SQL Database name |

## Optional Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `sql_version` | string | `"12.0"` | |
| `sku_name` | string | `"S1"` | Basic, S0-S12, P1-P15 |
| `max_size_gb` | number | `250` | |
| `public_network_access_enabled` | bool | **`false`** | See "Why this defaults false" below |
| `allowed_ip_ranges` | list(object) | `[]` | Only takes effect if `public_network_access_enabled = true` |
| `allow_azure_services` | bool | `true` | Only takes effect if `public_network_access_enabled = true` |
| `enable_azure_ad_admin` | bool | `false` | |
| `enable_advanced_threat_protection` | bool | `true` | |
| `tags` | map(string) | `{}` | |

## Outputs

| Output | Description |
|---|---|
| `sql_server_id` | SQL Server resource ID — feed to `private-endpoints`' `target_resource_id` |
| `sql_server_name` | SQL Server name |
| `sql_server_fqdn` | Fully qualified domain name |
| `database_id` | SQL Database resource ID |
| `database_name` | SQL Database name |
| `connection_string` | Connection string (sensitive) |

## Why `public_network_access_enabled` defaults false

`azurerm_mssql_server` has no deny-by-default network ACL like Key Vault or
Storage Account — it's binary: a public endpoint gated by IP allow-list
firewall rules, or no public endpoint at all (private-endpoint-only). Per
`CONVENTIONS.md` #2, the secure default wins unless the caller opts out
visibly. If you're relying on `allowed_ip_ranges`/`allow_azure_services`,
you must also set `public_network_access_enabled = true` — that pairing is
deliberate, not a bug.

## Status

Production Ready. Uplifted 2026-08-14: switched to `CONVENTIONS.md` naming,
and changed the public-access default from implicitly-on (no control existed)
to explicitly-off. If your root relied on the old public+firewall-only
behavior, set `public_network_access_enabled = true` to keep it. Root code
written against the older `customer_short_name`/`environment`/`location_code`/
`instance_number`/`name_suffix` interface needs updating to pass `name` directly.
