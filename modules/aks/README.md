# Azure Kubernetes Service (AKS) Module

Creates an `azurerm_kubernetes_cluster` with a mandatory system node pool,
optional additional (user workload) node pools, SystemAssigned identity,
Azure CNI Overlay networking by default, and optional Entra ID RBAC and
Container Insights. See `CONVENTIONS.md` #1 (naming).

## Usage — development cluster

```hcl
module "aks" {
  source = "../../modules/aks"

  name                 = "aks-contoso-dev-uks-001"
  location             = var.location
  resource_group_name  = module.resource_groups.names["main"]
  vnet_subnet_id       = module.networking.subnet_ids["aks"]

  tags = local.default_tags
}
```

## Usage — production cluster with a dedicated workload pool

```hcl
module "aks" {
  source = "../../modules/aks"

  name                 = "aks-contoso-prod-uks-001"
  location             = var.location
  resource_group_name  = module.resource_groups.names["main"]
  vnet_subnet_id       = module.networking.subnet_ids["aks"]

  sku_tier                     = "Standard"
  automatic_upgrade_channel    = "patch"
  only_critical_addons_enabled = true

  default_node_pool = {
    vm_size            = "Standard_D4s_v5"
    min_count          = 3
    max_count          = 10
    availability_zones = ["1", "2", "3"]
  }

  additional_node_pools = {
    workload = {
      vm_size            = "Standard_D8s_v5"
      min_count          = 2
      max_count          = 20
      availability_zones = ["1", "2", "3"]
    }
  }

  enable_azure_ad_rbac             = true
  azure_ad_admin_group_object_ids  = [var.aks_admins_group_id]
  log_analytics_workspace_id       = local.log_analytics_workspace_id
  api_server_authorized_ip_ranges  = [var.office_cidr]

  tags = local.default_tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.container_registry["images"].id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}
```

## Required Variables

| Variable | Type | Description |
|---|---|---|
| `name` | string | Exact cluster name. Compute in the root — see `CONVENTIONS.md` #1. |
| `location` | string | Azure region |
| `resource_group_name` | string | Resource group name |
| `vnet_subnet_id` | string | Subnet for every node pool (default and additional) |

## Optional Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `dns_prefix` | string | `name` | |
| `kubernetes_version` | string | `null` (Azure's current default) | |
| `sku_tier` | string | `"Free"` | Free, Standard (99.95% SLA), Premium (+ LTS) |
| `automatic_upgrade_channel` | string | `"none"` | none, patch, stable, rapid, node-image |
| `private_cluster_enabled` | bool | `false` | API server reachable only from the VNet |
| `only_critical_addons_enabled` | bool | `false` | Push workloads onto `additional_node_pools` |
| `default_node_pool` | object | see below | Mandatory system pool |
| `additional_node_pools` | map(object) | `{}` | User workload pools, keyed by pool name (≤12 lowercase alphanumeric chars) |
| `network_plugin` | string | `"azure"` | azure or kubenet — see networking note below |
| `network_plugin_mode` | string | `"overlay"` | Azure CNI Overlay; set `null` for classic Azure CNI |
| `network_policy` | string | `null` | azure, calico, cilium, or null |
| `service_cidr` / `dns_service_ip` | string | `null` | Let Azure assign defaults unless you need specific ranges |
| `enable_azure_ad_rbac` | bool | `false` | |
| `azure_ad_admin_group_object_ids` | list(string) | `[]` | Only relevant when `enable_azure_ad_rbac = true` |
| `log_analytics_workspace_id` | string | `null` | Enables the Container Insights (`oms_agent`) add-on |
| `api_server_authorized_ip_ranges` | list(string) | `[]` | Empty = API server open to whatever `private_cluster_enabled` implies |
| `tags` | map(string) | `{}` | |

`default_node_pool` object fields (all optional): `name` (`"system"`),
`vm_size` (`"Standard_D2s_v5"`), `node_count` (`2`, used when
`auto_scaling_enabled = false`), `auto_scaling_enabled` (`true`), `min_count`
(`2`), `max_count` (`5`), `max_pods`, `availability_zones` (`[]`).

## Outputs

| Output | Description |
|---|---|
| `cluster_id` / `cluster_name` | |
| `fqdn` | Public FQDN, or the private one when `private_cluster_enabled` |
| `node_resource_group` | The `MC_*` resource group Azure manages for cluster infra |
| `kubelet_identity_object_id` | Grant registry/storage roles to **this**, not the cluster identity — it's what nodes actually use to pull images |
| `principal_id` | The cluster's own SystemAssigned identity |
| `kube_config_raw` | Sensitive — cluster-admin kubeconfig (only meaningful while local accounts are enabled) |
| `additional_node_pool_ids` | Map of pool name → resource ID |

## Networking: why Azure CNI Overlay is the default

Classic Azure CNI assigns every pod a routable IP from the node subnet —
`max_nodes * max_pods_per_node` addresses, easily thousands. Azure CNI
Overlay (`network_plugin = "azure"`, `network_plugin_mode = "overlay"`, this
module's default) assigns pod IPs from a separate overlay range instead, so
the node subnet only needs enough addresses for nodes — comparable to
`kubenet`'s subnet economy, without kubenet's limitations (no Windows nodes,
UDR-based routing, on Microsoft's deprecation path for new clusters). Set
`network_plugin_mode = null` only if a workload genuinely needs pod IPs
that are routable outside the cluster.

## Status

Implemented 2026-08-17, following `CONVENTIONS.md` end to end. Replaces an
earlier README-only draft that used the pre-uplift `customer_short_name`/
`environment`/`location_code` naming interface and the pre-v4-provider
`enable_auto_scaling` argument name (now `auto_scaling_enabled`) — that
draft's Terraform was never written, so there is no prior root code to
migrate.
