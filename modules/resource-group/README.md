# resource-group

Creates one or more resource groups from a map. Deliberately dumb: it does not
derive names from customer/environment/region — see `CONVENTIONS.md` for why
naming lives in the calling root, not in modules.

## Usage

```hcl
module "resource_groups" {
  source = "../../modules/resource-group"

  resource_groups = {
    network = { name = "rg-network-contoso-prod-uks", location = "uksouth" }
    data    = { name = "rg-data-contoso-prod-uks", location = "uksouth" }
  }

  tags = local.default_tags
}
```

## Inputs

| Variable | Type | Required | Description |
|---|---|---|---|
| `resource_groups` | `map(object({ name, location, tags = optional }))` | yes | Key is a logical name you reference elsewhere (e.g. `module.resource_groups.ids["network"]`). |
| `tags` | `map(string)` | no | Merged into every RG's tags; per-RG `tags` win on conflict. |

## Outputs

| Output | Description |
|---|---|
| `ids` | Map of logical name => resource group ID |
| `names` | Map of logical name => resource group name |

## Status

Production Ready — ported from the RADical Systems build (`modules/resource-group`), unchanged.
