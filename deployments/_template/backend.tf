# Backend Configuration for Remote State Storage
# Uncomment and configure for production use

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state"
#     storage_account_name = "sttfstatecontoso001"  # Must be globally unique
#     container_name       = "tfstate"
#     key                  = "contoso-eastus.tfstate"  # {customer}-{region}.tfstate
#     
#     # Optional: Use these for additional security
#     # use_azuread_auth     = true
#     # use_oidc             = true
#   }
# }

# Instructions:
# 1. Create a storage account for Terraform state (manually or via script)
# 2. Update the values above with your storage account details
# 3. Uncomment the backend block
# 4. Run: terraform init -reconfigure
