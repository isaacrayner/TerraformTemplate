# Input Variables — Azure Virtual Desktop Module

# =====================================================
# NAMING AND PLACEMENT (CONVENTIONS.md #1)
# =====================================================

variable "name_suffix" {
  description = "Naming suffix computed in the calling root's locals, e.g. local.name_prefix. Resources are named vdws-{suffix}, vdpool-{pool key}-{suffix}, vdag-{pool key}-{suffix} and vdscaling-{pool key}-{suffix}."
  type        = string
}

variable "location" {
  description = "Azure region where AVD resources will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for all AVD resources. Create it with the resource-group module; this module does not create one."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all AVD resources"
  type        = map(string)
  default     = {}
}

# =====================================================
# WORKSPACE CONFIG
# =====================================================

variable "workspace_friendly_name" {
  description = "Display name shown to users in the AVD client (e.g., 'Contoso Virtual Desktop (prod)')"
  type        = string
  default     = "Virtual Desktop"
}

variable "workspace_description" {
  description = "Description of the AVD workspace"
  type        = string
  default     = "Azure Virtual Desktop workspace"
}

# =====================================================
# HOST POOLS (the main configuration object)
# Each entry creates one host pool + app group + N session hosts.
# Use multiple entries for different user personas (e.g., general, power-users, developers).
# =====================================================

variable "host_pools" {
  description = <<-EOT
    Map of host pool configurations. Key is used as a name suffix (e.g., "general", "power-users").
    Each pool creates: a host pool, application group, workspace association, and N session host VMs.

    LARGE DEPLOYMENT EXAMPLE — three pools with different SKUs:
      host_pools = {
        "general"     = { session_host_count = 20, vm_size = "Standard_D4s_v5", ... }
        "power-users" = { session_host_count = 5,  vm_size = "Standard_D16s_v5", ... }
        "developers"  = { session_host_count = 10, vm_size = "Standard_D8s_v5", ... }
      }
  EOT
  type = map(object({
    # ── Pool type ──────────────────────────────────────────────────────────
    # type: "Pooled" (shared, multiple users per host) or "Personal" (dedicated per user)
    type = string
    # load_balancer_type: "BreadthFirst" or "DepthFirst" for Pooled; "Persistent" for Personal
    load_balancer_type = string
    # max_sessions_per_host: ignored for Personal pools; tune based on VM size
    max_sessions_per_host = optional(number, 12)
    # app_group_type: "Desktop" (full desktop) or "RemoteApp" (individual apps)
    app_group_type      = optional(string, "Desktop")
    start_vm_on_connect = optional(bool, true)
    friendly_name       = optional(string, null)

    # ── Session hosts ──────────────────────────────────────────────────────
    session_host_count = number
    vm_size            = string
    # vm_name_prefix: Windows VM names max 15 chars; prefix max 12 (3-digit suffix appended)
    vm_name_prefix = string
    # subnet_id: the full resource ID of the subnet session hosts should join
    subnet_id = string

    # ── OS image ───────────────────────────────────────────────────────────
    os_disk_type = optional(string, "Premium_LRS")

    # source_image_id: use a golden/custom image instead of a marketplace image.
    # Mutually exclusive with image_publisher/offer/sku — set one or the other.
    # Accepted formats:
    #   Azure Compute Gallery image version:
    #     /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Compute/
    #     galleries/{gallery}/images/{imageDef}/versions/{version|latest}
    #   Managed image:
    #     /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Compute/images/{name}
    source_image_id = optional(string, null)

    # Marketplace image fields — only used when source_image_id = null
    image_publisher = optional(string, "MicrosoftWindowsDesktop")
    # image_offer/sku: common options below
    #   Windows 11 AVD multi-session: offer="windows-11", sku="win11-23h2-avd"
    #   Windows 10 AVD multi-session: offer="Windows-10", sku="win10-22h2-avd-g2"
    #   Windows Server 2022:          offer="WindowsServer", sku="2022-datacenter-azure-edition"
    image_offer = optional(string, "windows-11")
    image_sku   = optional(string, "win11-23h2-avd")

    # ── Identity & enrollment ──────────────────────────────────────────────
    # aad_joined=true for Entra ID (modern, no domain required)
    # aad_joined=false for hybrid AD domain-join (set domain_join_* variables)
    aad_joined        = optional(bool, true)
    intune_enrollment = optional(bool, false)

    # ── Admin credentials ──────────────────────────────────────────────────
    admin_username = string
    admin_password = string

    # ── Licensing ─────────────────────────────────────────────────────────
    # "Windows_Client" enables Azure Hybrid Benefit for Windows 10/11 Enterprise images (saves ~40%).
    # Set to null to use standard pricing. "Windows_Server" is for Windows Server images.
    license_type = optional(string, "Windows_Client")

    # ── Scaling plan (Pooled pools only) ───────────────────────────────────
    # Automatically starts/stops hosts based on session demand
    enable_scaling_plan = optional(bool, false)
  }))

  sensitive = true

  validation {
    condition     = alltrue([for k, v in var.host_pools : contains(["Pooled", "Personal"], v.type)])
    error_message = "host_pools[*].type must be 'Pooled' or 'Personal'."
  }
  validation {
    condition     = alltrue([for k, v in var.host_pools : contains(["BreadthFirst", "DepthFirst", "Persistent"], v.load_balancer_type)])
    error_message = "host_pools[*].load_balancer_type must be 'BreadthFirst', 'DepthFirst', or 'Persistent'."
  }
  validation {
    condition     = alltrue([for k, v in var.host_pools : length(v.vm_name_prefix) <= 12])
    error_message = "host_pools[*].vm_name_prefix must be 12 characters or fewer (Windows VM names max 15 chars; 3-digit suffix is appended)."
  }
  validation {
    condition     = alltrue([for k, v in var.host_pools : v.session_host_count >= 1 && v.session_host_count <= 500])
    error_message = "host_pools[*].session_host_count must be between 1 and 500."
  }
}

# =====================================================
# SCALING PLAN SETTINGS
# Applied to all host pools that have enable_scaling_plan = true
# =====================================================

variable "scaling_plan_timezone" {
  description = "Timezone for scaling plan schedules (e.g., 'Eastern Standard Time', 'UTC', 'GMT Standard Time')"
  type        = string
  default     = "UTC"
}

variable "scaling_plan_peak_start_time" {
  description = "Time when peak hours begin (HH:MM format, 24-hour)"
  type        = string
  default     = "09:00"
}

variable "scaling_plan_peak_end_time" {
  description = "Time when peak hours end / ramp-down begins (HH:MM format, 24-hour)"
  type        = string
  default     = "18:00"
}
