# private-dns-zone

One private DNS zone plus its VNet links. Call once per zone (per Azure
service you privately expose), typically from the hub/shared-services root so
it can be linked to every spoke that needs it.

## Usage

```hcl
module "dns_blob" {
  source = "../../modules/private-dns-zone"

  zone_name           = "privatelink.blob.core.windows.net"
  resource_group_name = module.resource_groups.names["shared_dns"]

  vnet_links = {
    "link-hub"   = module.hub_network.vnet_id
    "link-spoke" = module.spoke_network.vnet_id
  }

  tags = local.default_tags
}
```

## Inputs

| Variable | Type | Required | Default | Description |
|---|---|---|---|---|
| `zone_name` | string | yes | — | e.g. `privatelink.blob.core.windows.net` |
| `resource_group_name` | string | yes | — | RG the zone lives in |
| `vnet_links` | map(string) | no | `{}` | link-name => VNet ID |
| `tags` | map(string) | no | `{}` | |

## Outputs

| Output | Description |
|---|---|
| `zone_id` | Private DNS zone resource ID — feed to `private-endpoints`' `private_dns_zone_ids` |
| `zone_name` | Zone name |

## Status

Production Ready — ported from the RADical Systems build (`modules/networking/private-dns-zone`), unchanged.
