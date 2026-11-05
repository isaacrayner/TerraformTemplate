# Azure Provider Configuration
#
# LANDING ZONE subscription (default provider — no alias):
#   Hub VNet + peering, shared Key Vault, Log Analytics, Microsoft Defender, Front Door + WAF
#
# COMPUTE subscription (alias = "compute"):
#   Spoke VNet, ACA, AVD, App Service/Functions, customer Key Vaults, databases, storage
#
# Both subscriptions must reside in the same Azure AD tenant.
# The service principal / managed identity running Terraform needs Contributor
# (or a custom role) on BOTH subscriptions.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ── Landing Zone subscription ──────────────────────────────────────────────────
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.landing_zone_subscription_id
}

# ── Compute subscription ───────────────────────────────────────────────────────
provider "azurerm" {
  alias = "compute"
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.compute_subscription_id
}

# Client config for the Landing Zone subscription (used for tenant_id in LZ resources)
data "azurerm_client_config" "current" {}

# Client config for the Compute subscription (used for tenant_id in compute resources)
data "azurerm_client_config" "compute" {
  provider = azurerm.compute
}
