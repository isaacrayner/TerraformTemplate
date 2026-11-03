# Azure API Management Module

resource "azurerm_api_management" "apim" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name

  public_network_access_enabled = var.public_network_access_enabled
  virtual_network_type          = var.virtual_network_type
  min_api_version               = var.min_api_version
  zones                         = var.availability_zones

  dynamic "virtual_network_configuration" {
    for_each = var.subnet_id != null ? [var.subnet_id] : []
    content {
      subnet_id = virtual_network_configuration.value
    }
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [var.identity_type] : []
    content {
      type = identity.value
    }
  }

  lifecycle {
    precondition {
      condition     = var.virtual_network_type == "None" || var.subnet_id != null
      error_message = "subnet_id is required when virtual_network_type is Internal or External."
    }

    # VNet integration and availability zones are Developer/Premium-only —
    # Microsoft docs, not the sku_name schema itself, enforce this; get it
    # wrong and the apply fails deep into provisioning instead of at plan time.
    precondition {
      condition     = var.virtual_network_type == "None" || contains(["Developer", "Premium"], split("_", var.sku_name)[0])
      error_message = "VNet integration (virtual_network_type != \"None\") requires the Developer or Premium sku_name tier."
    }

    precondition {
      condition     = length(var.availability_zones) == 0 || split("_", var.sku_name)[0] == "Premium"
      error_message = "availability_zones requires the Premium sku_name tier."
    }
  }

  tags = var.tags
}
