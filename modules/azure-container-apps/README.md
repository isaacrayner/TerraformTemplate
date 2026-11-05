# Module: azure-container-apps

Deploys an **Azure Container App Environment** with multiple Container Apps, optional Container Registry, and automatic managed identity wiring. All apps in one module instance share an environment; for environment-level isolation, use separate module instances.

## What this module creates

| Resource | Count | Naming |
|---|---|---|
| Container App Environment | 1 | `cae-{name_suffix}` |
| Container App | 1 per app entry | `ca-{key}-{name_suffix}` |
| AcrPull Role Assignment | 1 per app (when `container_registry` is set) | — |

The resource group, Log Analytics workspace and container registry come from the caller (`CONVENTIONS.md` #1 and #4).

## Inputs

| Name | Type | Notes |
|---|---|---|
| `name_suffix` | string | Compute in the root, e.g. `local.name_prefix` |
| `location` | string | |
| `resource_group_name` | string | From the `resource-group` module |
| `log_analytics_workspace_id` | string | Optional. Shared workspace for environment logs |
| `infrastructure_subnet_id` | string | Optional. Delegated subnet for VNet integration |
| `internal_load_balancer_enabled` | bool | Default `false`. Requires `infrastructure_subnet_id` |
| `container_registry` | object `{ id, login_server }` | Optional. Apps pull with managed identity and get AcrPull |
| `container_apps` | map(object) | See `variables.tf` for every field |
| `tags` | map(string) | |

## Quick start

```hcl
module "aca" {
  source = "../../modules/azure-container-apps"

  name_suffix                = local.name_prefix
  location                   = var.location
  resource_group_name        = local.resource_group_name
  log_analytics_workspace_id = local.log_analytics_workspace_id

  container_registry = {
    id           = module.container_registry["apps"].id
    login_server = module.container_registry["apps"].login_server
  }

  container_apps = var.container_apps

  tags = var.tags
}
```

## Example: public web + internal API + background worker

```hcl
container_apps = {
  frontend = {
    image               = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
    cpu                 = 0.5
    memory              = "1Gi"
    min_replicas        = 2
    max_replicas        = 20
    ingress_external    = true
    ingress_target_port = 80
    http_scale_rule_requests = 50
  }

  api = {
    image               = "myacr.azurecr.io/myapi:v2.1"
    cpu                 = 1.0
    memory              = "2Gi"
    min_replicas        = 2
    max_replicas        = 30
    ingress_external    = false       # internal only — called by frontend
    ingress_target_port = 8080
    env_vars = {
      ASPNETCORE_ENVIRONMENT = "Production"
      DB_HOST                = "mydb.database.windows.net"
    }
    secret_env_vars = {
      DB_PASSWORD = "db-password-secret"  # references a Container App secret
    }
    http_scale_rule_requests = 100
  }

  worker = {
    image           = "myacr.azurecr.io/myworker:v1.5"
    cpu             = 2.0
    memory          = "4Gi"
    min_replicas    = 1
    max_replicas    = 10
    ingress_enabled = false           # no HTTP endpoint
    env_vars = {
      QUEUE_NAME = "jobs"
    }
  }
}
```

## VNet integration (private environment)

```hcl
module "aca" {
  # ...
  infrastructure_subnet_id       = module.networking[0].subnet_ids["aca"]
  internal_load_balancer_enabled = true
}
```

Subnet requirements:
- Minimum size: `/27`
- Must be delegated to `Microsoft.App/environments`
- Must **not** have NSG rules blocking the ACA control plane

Add this delegation in the networking module's subnet definition:
```hcl
subnets = {
  aca = {
    address_prefix = "10.0.20.0/23"
    delegation = {
      name    = "aca-delegation"
      service = "Microsoft.App/environments"
    }
  }
}
```

## CPU / Memory valid pairings

| CPU | Memory options |
|-----|----------------|
| 0.25 | 0.5Gi |
| 0.5  | 1Gi |
| 0.75 | 1.5Gi |
| 1.0  | 2Gi |
| 1.25 | 2.5Gi |
| 1.5  | 3Gi |
| 1.75 | 3.5Gi |
| 2.0  | 4Gi |
| 4.0  | 8Gi |

## Accessing outputs

```hcl
# URL for the frontend app
output "frontend_url" {
  value = module.aca.container_app_urls["frontend"]
}

```

## Variable reference

See `variables.tf` for full descriptions and validation rules. All variables in `container_apps` are documented inline.
