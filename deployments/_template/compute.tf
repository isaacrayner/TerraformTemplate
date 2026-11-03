# Virtual machines — Compute subscription.
#
# SSH-only Linux VMs. Public IP resources are composed separately and passed by
# ID; the default is a private-only NIC.

module "virtual_machine" {
  for_each  = var.virtual_machines
  source    = "../../modules/virtual-machine"
  providers = { azurerm = azurerm.compute }

  name                   = "vm-${each.key}-${local.name_prefix}"
  network_interface_name = "nic-${each.key}-${local.name_prefix}"
  location               = var.location
  resource_group_name    = local.resource_group_name
  subnet_id              = module.spoke_networking[0].subnet_ids[each.value.subnet_key]

  size                           = each.value.size
  zone                           = each.value.zone
  admin_username                 = each.value.admin_username
  admin_ssh_public_key           = each.value.admin_ssh_public_key
  private_ip_address             = each.value.private_ip_address
  public_ip_address_id           = each.value.public_ip_address_id
  accelerated_networking_enabled = each.value.accelerated_networking_enabled
  source_image                   = each.value.source_image
  os_disk_storage_account_type   = each.value.os_disk_storage_account_type
  os_disk_size_gb                = each.value.os_disk_size_gb

  tags = merge(var.tags, { Purpose = each.key })
}

module "diag_virtual_machine" {
  for_each  = local.diagnostics_enabled ? var.virtual_machines : {}
  source    = "../../modules/diagnostic-setting"
  providers = { azurerm = azurerm.compute }

  name                       = "diag-${module.virtual_machine[each.key].name}"
  target_resource_id         = module.virtual_machine[each.key].id
  log_analytics_workspace_id = local.log_analytics_workspace_id
  log_category_groups        = []
}
