# private-endpoints

One private endpoint for one PaaS service sub-resource, plus its DNS zone
group. Call once per sub-resource (blob and file on the same storage account
are two calls, two endpoints).

> Rewritten 2026-08-14: this README previously described a different,
> unbuilt interface (customer/environment/region baked into the module,
> naming derived internally). The actual module — ported from the RADical
> Systems build — takes an explicit `name` instead; see `CONVENTIONS.md` for
> why. If you wrote root code against the old interface, it needs updating.

## Usage

```hcl
module "pe_blob" {
  source = "../../modules/private-endpoints"

  name                = "pep-blob-contoso-prod-uks-001"
  resource_group_name = module.resource_groups.names["network"]
  location             = var.location
  subnet_id            = module.networking.subnet_ids["privatelink"]

  target_resource_id   = module.storage_account.storage_account_id
  subresource_names    = ["blob"]
  private_dns_zone_ids = [module.dns_blob.zone_id]

  tags = local.default_tags
}
```

The target service must have `public_network_access_enabled = false` (or
equivalent) for the private endpoint to be the only path in — this module
does not disable public access on your behalf.

## Inputs

| Variable | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | string | yes | — | Full private endpoint name |
| `resource_group_name` | string | yes | — | |
| `location` | string | yes | — | |
| `subnet_id` | string | yes | — | Must have PE network policies disabled |
| `target_resource_id` | string | yes | — | The PaaS resource being exposed |
| `subresource_names` | list(string) | yes | — | See reference table below |
| `private_dns_zone_ids` | list(string) | no | `[]` | From `private-dns-zone` module |
| `tags` | map(string) | no | `{}` | |

## Outputs

| Output | Description |
|---|---|
| `resource_id` | Private endpoint resource ID |
| `private_ip` | Private IP assigned to the endpoint |

## Subresource name reference

| Service | `subresource_names` | DNS zone |
|---|---|---|
| Storage Account | `blob`, `file`, `queue`, `table`, `dfs` | `privatelink.{blob,file,queue,table,dfs}.core.windows.net` |
| Key Vault | `vault` | `privatelink.vaultcore.azure.net` |
| SQL Database | `sqlServer` | `privatelink.database.windows.net` |
| Cosmos DB | `Sql`, `MongoDB`, `Cassandra`, `Gremlin`, `Table` | `privatelink.documents.azure.com` (SQL API) |
| App Service / Functions | `sites` | `privatelink.azurewebsites.net` |
| Container Registry | `registry` | `privatelink.azurecr.io` |
| Redis Cache | `redisCache` | `privatelink.redis.cache.windows.net` |
| Event Hubs / Service Bus | `namespace` | `privatelink.{servicebus,eventhub}.windows.net` |
| PostgreSQL / MySQL | `postgresqlServer` / `mysqlServer` | `privatelink.{postgres,mysql}.database.azure.com` |

## Status

Production Ready — adapted from the RADical Systems build (`modules/networking/private-endpoint`). Naming interface changed from the original README's draft; see note above.
