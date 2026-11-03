# Azure Virtual Desktop Module
# Supports multiple host pools — each pool has its own VM SKU, session count, and config.
# Pattern: one workspace shared across all pools; each pool gets its own app group.
#
# Per CONVENTIONS.md #1, names come from the caller (var.name_suffix, computed
# in the root's locals) and the resource group from the resource-group module.
# This module creates no resource group of its own.

locals {
  # var.host_pools is sensitive because it carries admin passwords, and a
  # sensitive value cannot drive for_each (CONVENTIONS.md #5). Only pool keys
  # and counts become visible; admin_password stays redacted by the provider
  # schema on azurerm_windows_virtual_machine.
  host_pools = nonsensitive(var.host_pools)

  # Flatten pools → individual session hosts so we can create VMs with for_each.
  # Key format: "{pool_key}-{zero-padded-index}" e.g. "general-001", "power-users-003"
  session_hosts = merge([
    for pool_key, pool in local.host_pools : {
      for i in range(pool.session_host_count) :
      "${pool_key}-${format("%03d", i + 1)}" => {
        pool_key = pool_key
        pool     = pool
        index    = i + 1
      }
    }
  ]...)
}

# =====================================================
# WORKSPACE
# Users connect to this in the AVD client — one per deployment.
# =====================================================

resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = "vdws-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  friendly_name       = var.workspace_friendly_name
  description         = var.workspace_description
  tags                = var.tags
}

# =====================================================
# HOST POOLS
# One per entry in var.host_pools.
# =====================================================

resource "azurerm_virtual_desktop_host_pool" "pools" {
  for_each = local.host_pools

  name                = "vdpool-${each.key}-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  type               = each.value.type
  load_balancer_type = each.value.load_balancer_type
  # Personal pools don't use session limits; 999999 is the Azure no-limit sentinel value.
  maximum_sessions_allowed = each.value.type == "Personal" ? 999999 : each.value.max_sessions_per_host
  start_vm_on_connect      = each.value.start_vm_on_connect
  validate_environment     = false
  friendly_name            = coalesce(each.value.friendly_name, "${each.key} pool")

  tags = var.tags
}

# Registration tokens — VMs use these to join the host pool.
# Tokens expire 48 h after first apply; ignore_changes prevents re-creation on every run.
resource "azurerm_virtual_desktop_host_pool_registration_info" "registration" {
  for_each = local.host_pools

  hostpool_id     = azurerm_virtual_desktop_host_pool.pools[each.key].id
  expiration_date = timeadd(timestamp(), "48h")

  lifecycle {
    ignore_changes = [expiration_date]
  }
}

# =====================================================
# APPLICATION GROUPS
# One Desktop app group per pool; associated with the shared workspace.
# =====================================================

resource "azurerm_virtual_desktop_application_group" "app_groups" {
  for_each = local.host_pools

  name                = "vdag-${each.key}-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = each.value.app_group_type
  host_pool_id        = azurerm_virtual_desktop_host_pool.pools[each.key].id
  friendly_name       = coalesce(each.value.friendly_name, "${each.key} Desktop")

  tags = var.tags
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "assoc" {
  for_each = local.host_pools

  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.app_groups[each.key].id
}

# =====================================================
# SESSION HOST NETWORK INTERFACES
# =====================================================

resource "azurerm_network_interface" "session_host_nic" {
  for_each = local.session_hosts

  name                = "nic-${each.value.pool.vm_name_prefix}${format("%03d", each.value.index)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = each.value.pool.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# =====================================================
# SESSION HOST VMs
# Windows VMs named: {vm_name_prefix}{001..N}
# Example: avdgen001, avdgen002 ... avdgen020
# =====================================================

resource "azurerm_windows_virtual_machine" "session_hosts" {
  for_each = local.session_hosts

  name                = "${each.value.pool.vm_name_prefix}${format("%03d", each.value.index)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = each.value.pool.vm_size
  admin_username      = each.value.pool.admin_username
  admin_password      = each.value.pool.admin_password

  network_interface_ids = [azurerm_network_interface.session_host_nic[each.key].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = each.value.pool.os_disk_type
  }

  # source_image_id and source_image_reference are mutually exclusive on this resource.
  # When source_image_id is set (golden/custom image), the dynamic block produces nothing.
  source_image_id = each.value.pool.source_image_id

  dynamic "source_image_reference" {
    for_each = each.value.pool.source_image_id == null ? [1] : []
    content {
      publisher = each.value.pool.image_publisher
      offer     = each.value.pool.image_offer
      sku       = each.value.pool.image_sku
      version   = "latest"
    }
  }

  # Windows_Client enables Azure Hybrid Benefit for Windows 10/11 Enterprise AVD images.
  # Set license_type = null to use standard (non-HB) pricing.
  license_type = each.value.pool.license_type

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# =====================================================
# EXTENSIONS
# Order: AAD join → AVD DSC agent (registers with host pool)
# =====================================================

# AAD / Entra ID join (for aad_joined = true pools)
resource "azurerm_virtual_machine_extension" "aad_join" {
  for_each = { for k, v in local.session_hosts : k => v if v.pool.aad_joined }

  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_hosts[each.key].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "2.0"
  auto_upgrade_minor_version = true

  # Enable Intune enrollment alongside AAD join when requested
  settings = each.value.pool.intune_enrollment ? jsonencode({
    mdmId = "0000000a-0000-0000-c000-000000000000"
  }) : null

  tags = var.tags
}

# AVD agent — registers the VM with its host pool.
# The DSC artifact URL is maintained by Microsoft; update to the latest version as needed.
# Current URL: https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02790.438.zip
resource "azurerm_virtual_machine_extension" "avd_dsc" {
  for_each = local.session_hosts

  name                       = "AVDAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_hosts[each.key].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    modulesUrl            = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02790.438.zip"
    configurationFunction = "Configuration.ps1\\AddSessionHost"
    properties = {
      HostPoolName          = azurerm_virtual_desktop_host_pool.pools[each.value.pool_key].name
      RegistrationInfoToken = azurerm_virtual_desktop_host_pool_registration_info.registration[each.value.pool_key].token
      AadJoin               = each.value.pool.aad_joined
    }
  })

  depends_on = [azurerm_virtual_machine_extension.aad_join]

  tags = var.tags
}

# =====================================================
# SCALING PLANS (Pooled pools only, when enabled)
# Automatically starts/stops hosts based on session load.
# =====================================================

resource "azurerm_virtual_desktop_scaling_plan" "scaling" {
  for_each = {
    for k, v in local.host_pools : k => v
    if v.enable_scaling_plan && v.type == "Pooled"
  }

  name                = "vdscaling-${each.key}-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  friendly_name       = "${each.key} Scaling Plan"
  time_zone           = var.scaling_plan_timezone

  schedule {
    name                                 = "Weekdays"
    days_of_week                         = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    ramp_up_start_time                   = "08:00"
    ramp_up_load_balancing_algorithm     = "BreadthFirst"
    ramp_up_minimum_hosts_percent        = 20
    ramp_up_capacity_threshold_percent   = 60
    peak_start_time                      = var.scaling_plan_peak_start_time
    peak_load_balancing_algorithm        = "BreadthFirst"
    ramp_down_start_time                 = var.scaling_plan_peak_end_time
    ramp_down_load_balancing_algorithm   = "DepthFirst"
    ramp_down_minimum_hosts_percent      = 10
    ramp_down_force_logoff_users         = false
    ramp_down_wait_time_minutes          = 45
    ramp_down_notification_message       = "Session will end in 45 minutes. Please save your work."
    ramp_down_capacity_threshold_percent = 5
    ramp_down_stop_hosts_when            = "ZeroActiveSessions"
    off_peak_start_time                  = "20:00"
    off_peak_load_balancing_algorithm    = "DepthFirst"
  }

  host_pool {
    hostpool_id          = azurerm_virtual_desktop_host_pool.pools[each.key].id
    scaling_plan_enabled = true
  }

  tags = var.tags
}
