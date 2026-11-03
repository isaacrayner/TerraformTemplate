variable "name" {
  description = "Exact Linux VM resource name."
  type        = string
}

variable "computer_name" {
  description = "Guest OS hostname. Null lets Azure derive it from name."
  type        = string
  default     = null
}

variable "network_interface_name" {
  description = "Exact primary NIC name."
  type        = string
}

variable "location" {
  description = "Azure region for the VM and NIC."
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group name."
  type        = string
}

variable "subnet_id" {
  description = "Subnet resource ID for the primary NIC."
  type        = string
}

variable "size" {
  description = "Azure VM size."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "zone" {
  description = "Optional availability zone."
  type        = string
  default     = null
}

variable "admin_username" {
  description = "Linux administrator username. Password authentication is disabled."
  type        = string
  default     = "azureadmin"
}

variable "admin_ssh_public_key" {
  description = "OpenSSH public key contents, not a local filesystem path."
  type        = string

  validation {
    condition     = can(regex("^(ssh-(rsa|ed25519)|ecdsa-sha2-nistp(256|384|521)) ", trimspace(var.admin_ssh_public_key)))
    error_message = "admin_ssh_public_key must contain a supported OpenSSH public key."
  }
}

variable "private_ip_address" {
  description = "Optional static private IP. Null uses dynamic allocation."
  type        = string
  default     = null
}

variable "public_ip_address_id" {
  description = "Optional existing Public IP resource ID. Null creates a private-only NIC."
  type        = string
  default     = null
}

variable "accelerated_networking_enabled" {
  description = "Enable accelerated networking when supported by the selected size."
  type        = bool
  default     = false
}

variable "source_image" {
  description = "Azure Marketplace image reference. The default is Ubuntu 22.04 Gen2."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = optional(string, "latest")
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
  }
}

variable "os_disk_name" {
  description = "Optional exact OS disk name."
  type        = string
  default     = null
}

variable "os_disk_caching" {
  description = "OS disk caching mode."
  type        = string
  default     = "ReadWrite"

  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.os_disk_caching)
    error_message = "os_disk_caching must be None, ReadOnly, or ReadWrite."
  }
}

variable "os_disk_storage_account_type" {
  description = "Managed OS disk storage type."
  type        = string
  default     = "Premium_LRS"
}

variable "os_disk_size_gb" {
  description = "Optional OS disk size in GB. Null uses the image default."
  type        = number
  default     = null
}

variable "secure_boot_enabled" {
  description = "Enable Trusted Launch Secure Boot. Requires a compatible Gen2 image and size."
  type        = bool
  default     = true
}

variable "vtpm_enabled" {
  description = "Enable virtual TPM. Requires a compatible Gen2 image and size."
  type        = bool
  default     = true
}

variable "custom_data" {
  description = "Optional base64-encoded cloud-init/custom data."
  type        = string
  default     = null
  sensitive   = true
}

variable "tags" {
  description = "Tags applied to the VM and NIC."
  type        = map(string)
  default     = {}
}
