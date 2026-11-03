# Input Variables — Azure Container Apps Module

# =====================================================
# NAMING AND PLACEMENT (CONVENTIONS.md #1)
# =====================================================

variable "name_suffix" {
  description = "Naming suffix computed in the calling root's locals, e.g. local.name_prefix. Resources are named cae-{suffix} and ca-{app key}-{suffix}."
  type        = string
}

variable "location" {
  description = "Azure region where ACA resources will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the environment and apps. Create it with the resource-group module; this module does not create one."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all ACA resources"
  type        = map(string)
  default     = {}
}

# =====================================================
# CONTAINER APP ENVIRONMENT
# One environment hosts all container apps in this module instance.
# For workload isolation, deploy separate module instances.
# =====================================================

variable "infrastructure_subnet_id" {
  description = <<-EOT
    Subnet ID for VNet integration (Consumption plan with VNet). Leave null for public environment.
    The subnet must be delegated to 'Microsoft.App/environments' and be at least /27.
    Required if internal_load_balancer_enabled = true.
  EOT
  type        = string
  default     = null
}

variable "internal_load_balancer_enabled" {
  description = "Deploy the environment with an internal (private) load balancer. Requires infrastructure_subnet_id."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace that receives the environment's logs (CONVENTIONS.md #4). Null disables log shipping."
  type        = string
  default     = null
}

# =====================================================
# CONTAINER REGISTRY (optional)
# Pass a registry created elsewhere (e.g. the container-registry module).
# Every app then pulls with its SystemAssigned identity and is granted
# AcrPull on the registry.
# =====================================================

variable "container_registry" {
  description = "Existing registry to pull images from: { id, login_server }. Null means public images only."
  type = object({
    id           = string
    login_server = string
  })
  default = null
}

# =====================================================
# CONTAINER APPS
# Each entry deploys one Container App into the shared environment.
# Key becomes part of the resource name (e.g., "api", "worker", "frontend").
# =====================================================

variable "container_apps" {
  description = <<-EOT
    Map of container apps to deploy into the shared Container App Environment.
    Key is used as a name suffix (e.g., "api", "worker", "frontend").

    EXAMPLE — typical three-tier app:
      container_apps = {
        "frontend" = {
          image            = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
          cpu              = 0.5
          memory           = "1Gi"
          ingress_external = true
          ingress_target_port = 80
        }
        "api" = {
          image            = "myacr.azurecr.io/myapi:v1.0"
          cpu              = 1.0
          memory           = "2Gi"
          ingress_external = false
          ingress_target_port = 8080
          min_replicas     = 2
          max_replicas     = 20
        }
        "worker" = {
          image           = "myacr.azurecr.io/myworker:v1.0"
          cpu             = 2.0
          memory          = "4Gi"
          ingress_enabled = false
          min_replicas    = 1
          max_replicas    = 10
        }
      }
  EOT
  type = map(object({
    # ── Image ─────────────────────────────────────────────────────────────
    image = string

    # ── Resources ─────────────────────────────────────────────────────────
    # cpu/memory must be a valid pairing: https://learn.microsoft.com/azure/container-apps/containers
    # Examples: cpu=0.25/memory="0.5Gi", cpu=0.5/memory="1Gi", cpu=1.0/memory="2Gi"
    cpu    = number
    memory = string

    # ── Scaling ───────────────────────────────────────────────────────────
    min_replicas = optional(number, 1)
    max_replicas = optional(number, 10)
    # revision_mode: "Single" (one active revision) or "Multiple" (A/B / canary)
    revision_mode = optional(string, "Single")
    # http_scale_rule_requests: scale out when concurrent HTTP requests exceed this threshold
    http_scale_rule_requests = optional(number, null)

    # ── Environment variables ──────────────────────────────────────────────
    # env_vars: plain-text key/value pairs
    env_vars = optional(map(string), {})
    # secrets: key = secret name, value = secret value. Defined on the container app resource.
    # WARNING: secret values are stored in Terraform state. Use Key Vault references in production.
    # Example: secrets = { "db-password" = "supersecret" }
    secrets = optional(map(string), {})
    # secret_env_vars: key = env var name, value = secret name (must exist in secrets above)
    secret_env_vars = optional(map(string), {})

    # ── Ingress ───────────────────────────────────────────────────────────
    ingress_enabled     = optional(bool, true)
    ingress_external    = optional(bool, false)
    ingress_target_port = optional(number, 80)
    # ingress_transport: "auto", "http", "http2", "tcp"
    ingress_transport = optional(string, "auto")
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.container_apps : contains(["Single", "Multiple"], v.revision_mode)])
    error_message = "container_apps[*].revision_mode must be 'Single' or 'Multiple'."
  }
  validation {
    condition     = alltrue([for k, v in var.container_apps : can(regex("^[a-z0-9-]{1,20}$", k))])
    error_message = "container_apps keys must be 1-20 lowercase alphanumeric characters or hyphens."
  }
}
