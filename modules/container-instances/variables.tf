# Input Variables for Container Instances Module

variable "name" {
  description = "Exact container group name. Compute it in the calling root's locals — see CONVENTIONS.md #1."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{1,63}$", var.name))
    error_message = "Container group name must be 1-63 lowercase alphanumeric characters or hyphens."
  }
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where the container group will be created"
  type        = string
}

variable "os_type" {
  description = "Linux or Windows"
  type        = string
  default     = "Linux"
  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "os_type must be Linux or Windows."
  }
}

variable "containers" {
  description = "One or more containers in the group. All containers in a group share the same IP and lifecycle."
  type = list(object({
    name   = string
    image  = string
    cpu    = number
    memory = number

    commands                     = optional(list(string), [])
    environment_variables        = optional(map(string), {})
    secure_environment_variables = optional(map(string), {})

    ports = optional(list(object({
      port     = number
      protocol = optional(string, "TCP")
    })), [])

    # Each entry fully defines a volume mount. Containers in the same group
    # that use the same volume `name` share that volume's data.
    volumes = optional(list(object({
      name                 = string
      mount_path           = string
      read_only            = optional(bool, false)
      empty_dir            = optional(bool, false)
      share_name           = optional(string)
      storage_account_name = optional(string)
      storage_account_key  = optional(string)
      secret               = optional(map(string))
      git_repo = optional(object({
        url       = string
        directory = optional(string)
        revision  = optional(string)
      }))
    })), [])
  }))

  validation {
    condition     = length(var.containers) > 0
    error_message = "At least one container is required."
  }

  validation {
    condition     = length(distinct([for c in var.containers : c.name])) == length(var.containers)
    error_message = "Container names must be unique within the group."
  }
}

variable "ip_address_type" {
  description = "Public, Private (requires subnet_ids), or None"
  type        = string
  default     = "Private"
  validation {
    condition     = contains(["Public", "Private", "None"], var.ip_address_type)
    error_message = "ip_address_type must be Public, Private, or None."
  }
}

variable "subnet_ids" {
  description = "Subnet(s) for VNet integration. Required when ip_address_type = \"Private\". The subnet must be delegated to Microsoft.ContainerInstance/containerGroups — see README."
  type        = list(string)
  default     = []
}

variable "dns_name_label" {
  description = "DNS name label for the public IP (<label>.<region>.azurecontainer.io). Only applies when ip_address_type = \"Public\"."
  type        = string
  default     = null
}

variable "restart_policy" {
  description = "Always, OnFailure, or Never"
  type        = string
  default     = "Always"
  validation {
    condition     = contains(["Always", "OnFailure", "Never"], var.restart_policy)
    error_message = "restart_policy must be Always, OnFailure, or Never."
  }
}

variable "identity_type" {
  description = "Managed identity type, or null for none"
  type        = string
  default     = null
  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "identity_type must be null, SystemAssigned, UserAssigned, or \"SystemAssigned, UserAssigned\"."
  }
}

variable "image_registry_credentials" {
  description = "Credentials for pulling from private registries."
  type = list(object({
    server                    = string
    username                  = optional(string)
    password                  = optional(string)
    user_assigned_identity_id = optional(string)
  }))
  default   = []
  sensitive = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
