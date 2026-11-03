# Output Values — Azure Virtual Desktop Module

output "workspace_id" {
  description = "AVD Workspace resource ID"
  value       = azurerm_virtual_desktop_workspace.workspace.id
}

output "workspace_name" {
  description = "AVD Workspace name"
  value       = azurerm_virtual_desktop_workspace.workspace.name
}

output "host_pool_ids" {
  description = "Map of host pool keys to their resource IDs"
  value       = { for k, v in azurerm_virtual_desktop_host_pool.pools : k => v.id }
}

output "host_pool_names" {
  description = "Map of host pool keys to their resource names"
  value       = { for k, v in azurerm_virtual_desktop_host_pool.pools : k => v.name }
}

output "application_group_ids" {
  description = "Map of app group keys to their resource IDs"
  value       = { for k, v in azurerm_virtual_desktop_application_group.app_groups : k => v.id }
}

output "application_group_names" {
  description = "Map of app group keys to their resource names"
  value       = { for k, v in azurerm_virtual_desktop_application_group.app_groups : k => v.name }
}

output "session_host_ids" {
  description = "Map of session host keys to their VM resource IDs"
  value       = { for k, v in azurerm_windows_virtual_machine.session_hosts : k => v.id }
}

output "session_host_names" {
  description = "Map of session host keys to their VM names"
  value       = { for k, v in azurerm_windows_virtual_machine.session_hosts : k => v.name }
}

output "session_host_principal_ids" {
  description = "Map of session host keys to their SystemAssigned managed identity principal IDs (for RBAC)"
  value       = { for k, v in azurerm_windows_virtual_machine.session_hosts : k => v.identity[0].principal_id }
}

output "scaling_plan_ids" {
  description = "Map of scaling plan keys to their resource IDs (only populated when enable_scaling_plan = true)"
  value       = { for k, v in azurerm_virtual_desktop_scaling_plan.scaling : k => v.id }
}

output "session_host_count_per_pool" {
  description = "Map of pool keys to total session host count deployed"
  value       = { for k, v in local.host_pools : k => v.session_host_count }
}

output "total_session_host_count" {
  description = "Total number of session host VMs deployed across all pools"
  value       = length(local.session_hosts)
}
