# Azure Container Instances Module

Creates one `azurerm_container_group` (one or more containers sharing an IP
and lifecycle). **Private by default** (`ip_address_type = "Private"`),
matching the network-facing modules in this catalog — see `CONVENTIONS.md`
#1 (naming) and #2 (network access).

## Usage — private (default), single container

```hcl
module "container_instance" {
  source = "../../modules/container-instances"

  name                 = "aci-contoso-prod-uks-worker"
  location             = var.location
  resource_group_name  = module.resource_groups.names["main"]

  subnet_ids = [module.networking.subnet_ids["aci"]]

  containers = [
    {
      name   = "worker"
      image  = "myregistry.azurecr.io/worker:1.4.2"
      cpu    = 1
      memory = 2

      environment_variables = {
        QUEUE_NAME = "jobs"
      }
    }
  ]

  restart_policy = "OnFailure"

  tags = local.default_tags
}
```

The `aci` subnet must be delegated to
`Microsoft.ContainerInstance/containerGroups` and dedicated to container
groups (nothing else can share it):

```hcl
subnets = {
  aci = {
    address_prefix = "10.0.10.0/24"
    delegation = {
      name    = "aci-delegation"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      service = "Microsoft.ContainerInstance/containerGroups"
    }
  }
}
```

(Adjust to whatever shape your `networking` module's `subnets` variable
actually expects — check its README before copying this verbatim.)

## Usage — public, multi-container with a shared volume

```hcl
module "container_group" {
  source = "../../modules/container-instances"
  # ...

  ip_address_type = "Public"
  dns_name_label   = "contoso-web-prod"

  containers = [
    {
      name   = "web"
      image  = "nginx:1.27-alpine"
      cpu    = 0.5
      memory = 1
      ports  = [{ port = 80 }]
      volumes = [
        { name = "shared-config", mount_path = "/etc/nginx/conf.d", read_only = true,
          share_name = "nginx-config", storage_account_name = module.storage_account.storage_account_name,
          storage_account_key = module.storage_account.primary_access_key }
      ]
    },
    {
      name   = "log-shipper"
      image  = "fluent/fluentd:v1.17"
      cpu    = 0.5
      memory = 1
      volumes = [
        { name = "shared-config", mount_path = "/etc/nginx/conf.d", read_only = true,
          share_name = "nginx-config", storage_account_name = module.storage_account.storage_account_name,
          storage_account_key = module.storage_account.primary_access_key }
      ]
    }
  ]
}
```

Two containers referencing a volume with the same `name` share that volume
— there is no separate top-level "shared volumes" list; each container's
`volumes` entry is a complete, self-contained mount definition.

## Required Variables

| Variable | Type | Description |
|---|---|---|
| `name` | string | Exact container group name. Compute in the root — see `CONVENTIONS.md` #1. |
| `location` | string | Azure region |
| `resource_group_name` | string | Resource group name |
| `containers` | list(object) | At least one, unique `name`s. See structure below. |

### `containers[]` structure

Required per entry: `name`, `image`, `cpu`, `memory`. Optional: `commands`
(`[]`), `environment_variables` (`{}`), `secure_environment_variables`
(`{}`, provider-redacted in plan output), `ports` (`[]`, each `{ port,
protocol = "TCP" }`), `volumes` (`[]`, each `{ name, mount_path, read_only =
false, empty_dir = false, share_name, storage_account_name,
storage_account_key, secret, git_repo = { url, directory, revision } }` —
fill in only the fields for the volume type you're using).

CPU/memory must be a valid Azure combination — see [resource
limits](https://learn.microsoft.com/azure/container-instances/container-instances-region-availability)
for current values; they change more often than is worth hardcoding here.

## Optional Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `os_type` | string | `"Linux"` | Linux or Windows |
| `ip_address_type` | string | **`"Private"`** | Public, Private, or None — see "Why this defaults Private" below |
| `subnet_ids` | list(string) | `[]` | Required when `ip_address_type = "Private"` |
| `dns_name_label` | string | `null` | Only applies when `ip_address_type = "Public"` |
| `restart_policy` | string | `"Always"` | Always, OnFailure, or Never |
| `identity_type` | string | `null` | SystemAssigned, UserAssigned, or both |
| `image_registry_credentials` | list(object) | `[]` | Sensitive — see CONVENTIONS.md #5 note in `main.tf` |
| `tags` | map(string) | `{}` | |

## Outputs

| Output | Description |
|---|---|
| `container_group_id` / `container_group_name` | |
| `ip_address` | Public or private, depending on `ip_address_type` |
| `fqdn` | Only populated when `dns_name_label` is set |
| `principal_id` | Managed identity principal ID, `null` if `identity_type` is unset |

## Why `ip_address_type` defaults `"Private"`

Consistent with every other network-facing module in this catalog
(`CONVENTIONS.md` #2): a container group with no explicit private path gets
one anyway, on the theory that "public by accident" is a worse failure mode
than an extra line in tfvars. Set `"Public"` deliberately (as in the second
usage example) when the workload is meant to be internet-reachable.

## Not covered

Liveness/readiness probes, `init_container`, `exposed_port` (group-level
port exposure separate from `network_profile_id`, a legacy pre-subnet-
delegation VNet integration model this module doesn't use), and GPU
resources are valid `azurerm_container_group` arguments this module doesn't
expose. Add them as additional variables if a workload needs them.

## Status

Implemented 2026-08-17, following `CONVENTIONS.md` end to end. Replaces an
earlier README-only draft that used the pre-uplift `customer_short_name`/
`environment`/`location_code` naming interface and a top-level
"shared volumes" model that doesn't match the actual `azurerm_container_group`
schema (volumes are defined per-container, not as a separate group-level
list) — that draft's Terraform was never written, so there is no prior root
code to migrate.
