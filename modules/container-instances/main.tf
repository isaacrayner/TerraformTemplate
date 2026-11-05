# Azure Container Instances Module

resource "azurerm_container_group" "aci" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  ip_address_type     = var.ip_address_type
  restart_policy      = var.restart_policy
  dns_name_label      = var.dns_name_label
  subnet_ids          = var.subnet_ids

  dynamic "identity" {
    for_each = var.identity_type != null ? [var.identity_type] : []
    content {
      type = identity.value
    }
  }

  # image_registry_credentials carries passwords — for_each can't take a
  # sensitive-marked expression directly (CONVENTIONS.md #5).
  dynamic "image_registry_credential" {
    for_each = nonsensitive(var.image_registry_credentials)
    content {
      server                    = image_registry_credential.value.server
      username                  = image_registry_credential.value.username
      password                  = image_registry_credential.value.password
      user_assigned_identity_id = image_registry_credential.value.user_assigned_identity_id
    }
  }

  dynamic "container" {
    for_each = { for c in var.containers : c.name => c }
    content {
      name   = container.value.name
      image  = container.value.image
      cpu    = container.value.cpu
      memory = container.value.memory

      commands                     = container.value.commands
      environment_variables        = container.value.environment_variables
      secure_environment_variables = container.value.secure_environment_variables

      dynamic "ports" {
        for_each = container.value.ports
        content {
          port     = ports.value.port
          protocol = ports.value.protocol
        }
      }

      dynamic "volume" {
        for_each = { for v in container.value.volumes : v.name => v }
        content {
          name       = volume.value.name
          mount_path = volume.value.mount_path
          read_only  = volume.value.read_only
          empty_dir  = volume.value.empty_dir

          share_name           = volume.value.share_name
          storage_account_name = volume.value.storage_account_name
          storage_account_key  = volume.value.storage_account_key
          secret               = volume.value.secret

          dynamic "git_repo" {
            for_each = volume.value.git_repo != null ? [volume.value.git_repo] : []
            content {
              url       = git_repo.value.url
              directory = git_repo.value.directory
              revision  = git_repo.value.revision
            }
          }
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.ip_address_type != "Private" || length(var.subnet_ids) > 0
      error_message = "subnet_ids is required when ip_address_type is Private (the subnet must be delegated to Microsoft.ContainerInstance/containerGroups)."
    }

    precondition {
      condition     = var.dns_name_label == null || var.ip_address_type == "Public"
      error_message = "dns_name_label only applies when ip_address_type is Public."
    }

    precondition {
      condition     = length(var.containers) > 0
      error_message = "At least one container is required."
    }
  }

  tags = var.tags
}
