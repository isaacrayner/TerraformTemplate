# Input Variables for Deployment

# =====================================================
# CORE VARIABLES (Required for All Deployments)
# =====================================================

variable "customer_short_name" {
  description = "Short name for the customer (3-8 lowercase characters, e.g., 'contoso')"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{3,8}$", var.customer_short_name))
    error_message = "Customer short name must be 3-8 lowercase letters only."
  }
}

variable "environment" {
  description = "Environment name (prod, dev, staging, uat, test)"
  type        = string
  validation {
    condition     = contains(["prod", "dev", "staging", "uat", "test"], var.environment)
    error_message = "Environment must be one of: prod, dev, staging, uat, test."
  }
}

variable "location" {
  description = "Azure region where resources will be deployed (e.g., 'eastus', 'westeurope')"
  type        = string
}

variable "location_code" {
  description = "Short code for the Azure region (e.g., 'eus' for East US, 'weu' for West Europe)"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2,4}$", var.location_code))
    error_message = "Location code must be 2-4 lowercase letters."
  }
}

# ── SUBSCRIPTION IDs ────────────────────────────────────────────────────────────
# This template spans TWO Azure subscriptions:
#   landing_zone_subscription_id → shared platform: hub VNet, Key Vault, Log Analytics, Front Door
#   compute_subscription_id      → customer workloads: spoke VNet, ACA, AVD, databases, storage
# Both must be under the same Azure AD tenant.

variable "landing_zone_subscription_id" {
  description = "Subscription ID for the Landing Zone — hub networking, shared Key Vault, Log Analytics, Front Door"
  type        = string
}

variable "compute_subscription_id" {
  description = "Subscription ID for the Compute subscription — spoke networking, ACA, AVD, App Service, databases, storage"
  type        = string
}

variable "instance_number" {
  description = "Instance number for resource naming (typically 1 for first deployment)"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

# =====================================================
# MODULE CONTROL FLAGS (Boolean)
# ── Landing Zone resources (landing_zone_subscription_id) ─────────────────────
# =====================================================

variable "enable_hub_networking" {
  description = "Deploy hub VNet in the Landing Zone subscription (recommended: true)"
  type        = bool
  default     = true
}

variable "enable_shared_key_vault" {
  description = "Deploy a shared Key Vault in the Landing Zone subscription for platform secrets (AVD admin creds, certificates)"
  type        = bool
  default     = false
}

# ── Compute resources (compute_subscription_id) ───────────────────────────────

variable "enable_spoke_networking" {
  description = "Deploy spoke VNet in the Compute subscription (recommended: true)"
  type        = bool
  default     = true
}

# =====================================================
# STORAGE ACCOUNTS (Multiple Named Instances)
# =====================================================

variable "storage_accounts" {
  description = "Map of storage accounts to create. Key = suffix/purpose (e.g., 'data', 'logs', 'appX')"
  type = map(object({
    tier             = string       # Standard or Premium
    replication_type = string       # LRS, GRS, ZRS, GZRS, RAGRS, RAGZRS
    blob_containers  = list(string) # List of container names to create
    network_access = optional(object({
      default_action                = optional(string, "Deny")
      bypass                        = optional(list(string), ["AzureServices"])
      ip_rules                      = optional(list(string), [])
      subnet_ids                    = optional(list(string), [])
      public_network_access_enabled = optional(bool, true)
    }), {}) # CONVENTIONS.md #2 — override per instance to relax network access deliberately
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.storage_accounts : can(regex("^[a-z0-9]{1,10}$", k))])
    error_message = "Storage account keys (suffixes) must be 1-10 lowercase alphanumeric characters (no hyphens)."
  }
}

# =====================================================
# KEY VAULTS (Multiple Named Instances)
# =====================================================

variable "key_vaults" {
  description = "Map of Key Vaults to create. Key = suffix/purpose (e.g., 'secrets', 'certs', 'appX')"
  type = map(object({
    sku_name    = string # standard or premium
    enable_rbac = bool   # Use RBAC (recommended)
    network_access = optional(object({
      default_action                = optional(string, "Deny")
      bypass                        = optional(list(string), ["AzureServices"])
      ip_rules                      = optional(list(string), [])
      subnet_ids                    = optional(list(string), [])
      public_network_access_enabled = optional(bool, true)
    }), {}) # CONVENTIONS.md #2 — override per instance to relax network access deliberately
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.key_vaults : can(regex("^[a-z0-9-]{1,12}$", k))])
    error_message = "Key Vault keys (suffixes) must be 1-12 lowercase alphanumeric characters or hyphens."
  }
}

# =====================================================
# SQL DATABASES (Multiple Named Instances)
# =====================================================

variable "sql_databases" {
  description = "Map of SQL Servers and Databases to create. Key = suffix/purpose (e.g., 'orders', 'inventory', 'appX')"
  type = map(object({
    admin_username                = string         # SQL admin username
    admin_password                = string         # SQL admin password (use Key Vault reference)
    database_name                 = string         # Name of the database
    sku_name                      = string         # Basic, S0, S1, S2, P1, P2, etc.
    max_size_gb                   = number         # Maximum database size
    zone_redundant                = optional(bool) # Enable zone redundancy (default: false)
    public_network_access_enabled = optional(bool) # Default false (CONVENTIONS.md #2) — set true only to deliberately use the public+firewall model instead of a private endpoint
  }))
  default   = {}
  sensitive = true

  validation {
    condition     = alltrue([for k, v in var.sql_databases : can(regex("^[a-z0-9-]{1,15}$", k))])
    error_message = "SQL database keys (suffixes) must be 1-15 lowercase alphanumeric characters or hyphens."
  }
}

# =====================================================
# DIAGNOSTICS
# The workspace lives in the Landing Zone subscription (shared resource group)
# and receives diagnostics from both subscriptions (CONVENTIONS.md #4).
# =====================================================

variable "enable_log_analytics" {
  description = "Create a shared Log Analytics workspace in the Landing Zone subscription when log_analytics_workspace_id is not supplied."
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Existing shared Log Analytics workspace resource ID. When set, this takes precedence and no deployment-local workspace is created."
  type        = string
  default     = null
}

variable "log_analytics_retention_in_days" {
  description = "Retention for the Log Analytics workspace created by this deployment."
  type        = number
  default     = 30

  validation {
    condition     = var.log_analytics_retention_in_days >= 30 && var.log_analytics_retention_in_days <= 730
    error_message = "log_analytics_retention_in_days must be between 30 and 730."
  }
}

variable "log_analytics_daily_quota_gb" {
  description = "Daily ingestion quota for the workspace created by this deployment. Use -1 for unlimited."
  type        = number
  default     = -1

  validation {
    condition     = var.log_analytics_daily_quota_gb == -1 || var.log_analytics_daily_quota_gb > 0
    error_message = "log_analytics_daily_quota_gb must be -1 or greater than zero."
  }
}

# =====================================================
# HUB NETWORKING (Landing Zone subscription)
# =====================================================

variable "hub_vnet_address_space" {
  description = "Address space for the hub VNet in the Landing Zone subscription (e.g., ['10.100.0.0/16'])"
  type        = list(string)
  default     = ["10.100.0.0/16"]
}

variable "hub_subnets" {
  description = <<-EOT
    Subnets for the hub VNet in the Landing Zone subscription.
    Set name = "GatewaySubnet" for the VPN/ExpressRoute gateway subnet — Azure requires this exact name.
    GatewaySubnet and AzureFirewallSubnet are automatically excluded from NSG attachment.
  EOT
  type = map(object({
    address_prefix    = string
    name              = optional(string, null) # Override generated name (required for GatewaySubnet etc.)
    service_endpoints = optional(list(string))
    delegation = optional(object({
      name    = string
      service = string
      actions = optional(list(string), [])
    }))
  }))
  default = {
    GatewaySubnet = {
      address_prefix = "10.100.0.0/27" # /27 minimum for VPN/ExpressRoute gateway
      name           = "GatewaySubnet" # Azure requires this exact name
    }
    management = {
      address_prefix = "10.100.1.0/24"
    }
  }
}

# =====================================================
# SPOKE NETWORKING (Compute subscription)
# =====================================================

variable "spoke_vnet_address_space" {
  description = "Address space for the spoke VNet in the Compute subscription (e.g., ['10.0.0.0/16'])"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "spoke_subnets" {
  description = <<-EOT
    Subnets for the spoke VNet in the Compute subscription.
    Add avd-* subnets when enable_avd = true.
    Add an "aca" subnet with Microsoft.App/environments delegation when enable_aca = true.
  EOT
  type = map(object({
    address_prefix    = string
    name              = optional(string, null) # Override generated name (required for GatewaySubnet etc.)
    service_endpoints = optional(list(string))
    # delegation: required for ACA VNet integration (service = "Microsoft.App/environments")
    delegation = optional(object({
      name    = string
      service = string
      actions = optional(list(string), [])
    }))
  }))
  default = {
    gateway = {
      address_prefix = "10.0.0.0/24"
    }
    appservice = {
      address_prefix = "10.0.1.0/24"
    }
    vms = {
      address_prefix = "10.0.2.0/24"
    }
    data = {
      address_prefix = "10.0.3.0/24"
    }
    mgmt = {
      address_prefix = "10.0.255.0/24"
    }
  }
}

variable "existing_compute_resource_group_name" {
  description = "Existing resource group in the Compute subscription. When set, no compute resource group is created and all compute resources go here."
  type        = string
  default     = ""
}

# =====================================================
# STAGE 2 WORKLOADS
# =====================================================

variable "application_insights" {
  description = "Application Insights components keyed by workload name. Requires an effective Log Analytics workspace."
  type = map(object({
    application_type     = optional(string, "web")
    daily_data_cap_in_gb = optional(number)
    retention_in_days    = optional(number, 90)
    sampling_percentage  = optional(number, 100)
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.application_insights) : can(regex("^[a-z0-9-]{1,12}$", key))])
    error_message = "Application Insights keys must be 1-12 lowercase alphanumeric characters or hyphens."
  }
}

variable "container_registries" {
  description = "Container registries keyed by purpose."
  type = map(object({
    sku                           = optional(string, "Premium")
    public_network_access_enabled = optional(bool, false)
    export_policy_enabled         = optional(bool, false)
    zone_redundancy_enabled       = optional(bool, false)
    georeplications = optional(list(object({
      location                = string
      zone_redundancy_enabled = optional(bool, false)
      tags                    = optional(map(string), {})
    })), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.container_registries) : can(regex("^[a-z0-9]{1,10}$", key))])
    error_message = "Container Registry keys must be 1-10 lowercase alphanumeric characters."
  }
}

variable "web_apps" {
  description = "Linux Web Apps keyed by workload name. Use Key Vault reference strings rather than literal secrets in app_settings."
  type = map(object({
    service_plan_sku_name         = optional(string, "P1v3")
    public_network_access_enabled = optional(bool, false)
    vnet_integration_subnet_key   = optional(string)
    health_check_path             = optional(string)
    application_insights_key      = optional(string)
    container_registry_key        = optional(string)
    application_stack = optional(object({
      docker_image_name   = optional(string)
      docker_registry_url = optional(string)
      dotnet_version      = optional(string)
      go_version          = optional(string)
      java_server         = optional(string)
      java_server_version = optional(string)
      java_version        = optional(string)
      node_version        = optional(string)
      php_version         = optional(string)
      python_version      = optional(string)
    }))
    app_settings = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.web_apps) : can(regex("^[a-z0-9-]{1,12}$", key))])
    error_message = "Web App keys must be 1-12 lowercase alphanumeric characters or hyphens."
  }
}

variable "function_apps" {
  description = "Linux Function Apps keyed by workload name. Each references a storage account key in storage_accounts."
  type = map(object({
    service_plan_sku_name = optional(string, "EP1")
    storage_account_key   = string
    runtime = object({
      name    = string
      version = string
    })
    public_network_access_enabled = optional(bool, false)
    vnet_integration_subnet_key   = optional(string)
    application_insights_key      = optional(string)
    app_settings                  = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.function_apps) : can(regex("^[a-z0-9-]{1,12}$", key))])
    error_message = "Function App keys must be 1-12 lowercase alphanumeric characters or hyphens."
  }
}

variable "virtual_machines" {
  description = "SSH-only Linux VMs keyed by purpose."
  type = map(object({
    subnet_key                     = string
    size                           = optional(string, "Standard_D2s_v5")
    zone                           = optional(string)
    admin_username                 = optional(string, "azureadmin")
    admin_ssh_public_key           = string
    private_ip_address             = optional(string)
    public_ip_address_id           = optional(string)
    accelerated_networking_enabled = optional(bool, false)
    source_image = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = optional(string, "latest")
      }), {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
    })
    os_disk_storage_account_type = optional(string, "Premium_LRS")
    os_disk_size_gb              = optional(number)
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.virtual_machines) : can(regex("^[a-z0-9-]{1,12}$", key))])
    error_message = "Virtual Machine keys must be 1-12 lowercase alphanumeric characters or hyphens."
  }
}

# =====================================================
# FRONT DOOR + WAF VARIABLES (Optional)
# Front Door deploys to the Landing Zone subscription.
# Used when enable_front_door = true
# =====================================================

variable "enable_front_door" {
  description = "Deploy Front Door + WAF in the Landing Zone subscription (global entry point)"
  type        = bool
  default     = false
}


variable "front_door_sku_name" {
  description = "Front Door SKU: 'Standard_AzureFrontDoor' or 'Premium_AzureFrontDoor'. WAF managed rules require Premium."
  type        = string
  default     = "Premium_AzureFrontDoor"
  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.front_door_sku_name)
    error_message = "front_door_sku_name must be 'Standard_AzureFrontDoor' or 'Premium_AzureFrontDoor'."
  }
}

variable "front_door_response_timeout_seconds" {
  description = "Seconds Front Door waits for an origin response before timing out (16–240)"
  type        = number
  default     = 120
}

variable "front_door_endpoints" {
  description = "Map of Front Door endpoints. Most deployments only need the default entry."
  type = map(object({
    enabled = optional(bool, true)
  }))
  default = { default = {} }
}

variable "front_door_origin_groups" {
  description = <<-EOT
    Map of Front Door origin groups. Each group holds one or more backend origins.
    Key is the group name suffix (e.g., "frontend", "api").
    See modules/front-door/README.md for full examples.
  EOT
  type = map(object({
    session_affinity_enabled                   = optional(bool, false)
    health_probe_path                          = optional(string, "/")
    health_probe_protocol                      = optional(string, "Https")
    health_probe_interval_seconds              = optional(number, 100)
    load_balancing_sample_size                 = optional(number, 4)
    load_balancing_successful_samples_required = optional(number, 3)
    load_balancing_additional_latency_ms       = optional(number, 50)
    origins = map(object({
      host_name                      = string
      origin_host_header             = optional(string, null)
      http_port                      = optional(number, 80)
      https_port                     = optional(number, 443)
      priority                       = optional(number, 1)
      weight                         = optional(number, 1000)
      enabled                        = optional(bool, true)
      certificate_name_check_enabled = optional(bool, true)
    }))
  }))
  default = {}
}

variable "front_door_routes" {
  description = <<-EOT
    Map of Front Door routes. Each route connects an endpoint to an origin group.
    Key is the route name suffix (e.g., "frontend", "api").
    See modules/front-door/README.md for full examples.
  EOT
  type = map(object({
    endpoint_key                        = string
    origin_group_key                    = string
    patterns_to_match                   = optional(list(string), ["/*"])
    supported_protocols                 = optional(list(string), ["Http", "Https"])
    https_redirect                      = optional(bool, true)
    forwarding_protocol                 = optional(string, "HttpsOnly")
    cache_enabled                       = optional(bool, false)
    cache_query_string_caching_behavior = optional(string, "IgnoreQueryString")
  }))
  default = {}
}

# ── WAF ────────────────────────────────────────────────────────────────────────

variable "enable_waf" {
  description = "Enable WAF policy on Front Door. Managed rule sets require Premium SKU."
  type        = bool
  default     = true
}

variable "waf_mode" {
  description = "WAF mode: 'Prevention' (blocks) or 'Detection' (logs only). Start with Detection, switch to Prevention after tuning."
  type        = string
  default     = "Prevention"
}

variable "waf_managed_rule_sets" {
  description = "Microsoft-managed WAF rule sets (Premium SKU only). Defaults cover OWASP Top 10 and Bot Manager."
  type = list(object({
    type    = string
    version = string
    action  = optional(string, "Block")
    overrides = optional(list(object({
      rule_group_name = string
      rules = optional(list(object({
        rule_id = string
        enabled = bool
        action  = string
      })), [])
    })), [])
  }))
  default = [
    { type = "Microsoft_DefaultRuleSet", version = "2.1", overrides = [] },
    { type = "Microsoft_BotManagerRuleSet", version = "1.0", overrides = [] }
  ]
}

variable "waf_custom_rules" {
  description = "Custom WAF rules (IP block, geo-filter, rate limit). Applied before managed rule sets. See modules/front-door/README.md for examples."
  type = map(object({
    priority  = number
    rule_type = string
    action    = string
    match_conditions = list(object({
      match_variable     = string
      operator           = string
      match_values       = list(string)
      selector           = optional(string)
      negation_condition = optional(bool, false)
      transforms         = optional(list(string), [])
    }))
    rate_limit_duration_in_minutes = optional(number, 1)
    rate_limit_threshold           = optional(number, 1000)
  }))
  default = {}
}

# =====================================================
# AZURE VIRTUAL DESKTOP VARIABLES (Optional)
# Deployed to Compute subscription
# Used when enable_avd = true
# =====================================================

variable "enable_avd" {
  description = "Enable Azure Virtual Desktop module — host pools, session hosts, workspace (Compute subscription)"
  type        = bool
  default     = false
}


variable "avd_workspace_friendly_name" {
  description = "Display name shown to users in the AVD client (e.g., 'Contoso Virtual Desktop')"
  type        = string
  default     = "Virtual Desktop"
}

variable "avd_workspace_description" {
  description = "Description of the AVD workspace"
  type        = string
  default     = "Azure Virtual Desktop workspace"
}

variable "avd_host_pools" {
  description = <<-EOT
    Map of AVD host pool configurations. Key is used as a name suffix (e.g., "general", "power-users").
    subnet_key references a key in var.spoke_subnets — the full subnet ID is resolved in avd.tf.

    Each pool creates: host pool, app group, workspace association, and N session host VMs.

    LARGE DEPLOYMENT EXAMPLE:
      avd_host_pools = {
        general      = { session_host_count = 20, vm_size = "Standard_D4s_v5",  subnet_key = "avd-general",  ... }
        power-users  = { session_host_count = 5,  vm_size = "Standard_D16s_v5", subnet_key = "avd-power",    ... }
        personal     = { session_host_count = 10, vm_size = "Standard_D8s_v5",  subnet_key = "avd-personal", type = "Personal", load_balancer_type = "Persistent", ... }
      }
  EOT
  type = map(object({
    type                  = string
    load_balancer_type    = string
    max_sessions_per_host = optional(number, 12)
    app_group_type        = optional(string, "Desktop")
    start_vm_on_connect   = optional(bool, true)
    friendly_name         = optional(string, null)
    session_host_count    = number
    vm_size               = string
    vm_name_prefix        = string
    subnet_key            = string # must match a key in var.spoke_subnets
    os_disk_type          = optional(string, "Premium_LRS")
    # source_image_id: set to an Azure Compute Gallery or managed image resource ID to use
    # a golden image. When set, image_publisher/offer/sku are ignored.
    # Example: "/subscriptions/.../galleries/MyGallery/images/AVDGolden/versions/latest"
    source_image_id     = optional(string, null)
    image_publisher     = optional(string, "MicrosoftWindowsDesktop")
    image_offer         = optional(string, "windows-11")
    image_sku           = optional(string, "win11-23h2-avd")
    aad_joined          = optional(bool, true)
    intune_enrollment   = optional(bool, false)
    admin_username      = string
    admin_password      = string
    enable_scaling_plan = optional(bool, false)
    # "Windows_Client" enables Azure Hybrid Benefit (~40% savings) for Win10/11 Enterprise images.
    # Set to null for standard pricing. Use "Windows_Server" for Server SKU images.
    license_type = optional(string, "Windows_Client")
  }))
  default   = {}
  sensitive = true

  validation {
    condition     = alltrue([for k, v in var.avd_host_pools : contains(["Pooled", "Personal"], v.type)])
    error_message = "avd_host_pools[*].type must be 'Pooled' or 'Personal'."
  }
  validation {
    condition     = alltrue([for k, v in var.avd_host_pools : length(v.vm_name_prefix) <= 12])
    error_message = "avd_host_pools[*].vm_name_prefix must be 12 characters or fewer."
  }
}

variable "avd_scaling_plan_timezone" {
  description = "Timezone for AVD scaling plan schedules (e.g., 'Eastern Standard Time', 'UTC')"
  type        = string
  default     = "UTC"
}

variable "avd_scaling_plan_peak_start_time" {
  description = "Time when AVD peak hours begin (HH:MM 24-hour)"
  type        = string
  default     = "09:00"
}

variable "avd_scaling_plan_peak_end_time" {
  description = "Time when AVD peak hours end / ramp-down begins (HH:MM 24-hour)"
  type        = string
  default     = "18:00"
}

# =====================================================
# AZURE CONTAINER APPS VARIABLES (Optional)
# Deployed to Compute subscription
# Used when enable_aca = true
# =====================================================

variable "enable_aca" {
  description = "Enable Azure Container Apps module — environment + container apps (Compute subscription)"
  type        = bool
  default     = false
}


variable "aca_internal_load_balancer" {
  description = "Deploy the ACA environment with an internal (private) load balancer. Requires an 'aca' subnet in var.spoke_subnets with Microsoft.App/environments delegation."
  type        = bool
  default     = false
}

variable "aca_container_registry_key" {
  description = "Key in var.container_registries that the container apps pull from. The apps get AcrPull on it. Null means public images only."
  type        = string
  default     = null
}

variable "container_apps" {
  description = <<-EOT
    Map of container apps to deploy in the ACA environment.
    Key is used as a name suffix (e.g., "api", "worker", "frontend").

    EXAMPLE:
      container_apps = {
        frontend = { image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest", cpu = 0.5, memory = "1Gi", ingress_external = true }
        api      = { image = "myacr.azurecr.io/myapi:v1", cpu = 1.0, memory = "2Gi", ingress_external = false, min_replicas = 2, max_replicas = 20 }
        worker   = { image = "myacr.azurecr.io/worker:v1", cpu = 2.0, memory = "4Gi", ingress_enabled = false }
      }
  EOT
  type = map(object({
    image                    = string
    cpu                      = number
    memory                   = string
    min_replicas             = optional(number, 1)
    max_replicas             = optional(number, 10)
    revision_mode            = optional(string, "Single")
    http_scale_rule_requests = optional(number, null)
    env_vars                 = optional(map(string), {})
    # secrets: key = secret name, value = secret value. WARNING: stored in Terraform state.
    # Use Key Vault references instead of plain values in production.
    secrets = optional(map(string), {})
    # secret_env_vars: key = env var name, value = a secret name defined in secrets above
    secret_env_vars     = optional(map(string), {})
    ingress_enabled     = optional(bool, true)
    ingress_external    = optional(bool, false)
    ingress_target_port = optional(number, 80)
    ingress_transport   = optional(string, "auto")
  }))
  default = {}
}
