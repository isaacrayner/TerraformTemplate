resource "azurerm_network_interface" "this" {
  name                = var.network_interface_name
  location            = var.location
  resource_group_name = var.resource_group_name

  accelerated_networking_enabled = var.accelerated_networking_enabled

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address == null ? "Dynamic" : "Static"
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = var.public_ip_address_id
    primary                       = true
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = var.name
  computer_name       = var.computer_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.size
  zone                = var.zone

  network_interface_ids = [azurerm_network_interface.this.id]

  admin_username                  = var.admin_username
  disable_password_authentication = true
  custom_data                     = var.custom_data

  secure_boot_enabled = var.secure_boot_enabled
  vtpm_enabled        = var.vtpm_enabled

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    name                 = var.os_disk_name
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.source_image.publisher
    offer     = var.source_image.offer
    sku       = var.source_image.sku
    version   = var.source_image.version
  }

  boot_diagnostics {}

  tags = var.tags
}
