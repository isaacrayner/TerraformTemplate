# Private Connectivity (Optional, per-resource — CONVENTIONS.md #2)
#
# Not wired by default: enabling this for every resource in every deployment
# would force a privatelink subnet and a DNS zone per Azure service onto
# every customer regardless of budget, which is the opposite of "network
# access is a variable, not a mandate". Uncomment and adapt per resource
# where the customer wants (and is paying for) it.
#
# Prerequisite: add a subnet for private endpoints with disabled network
# policies, e.g. in terraform.tfvars:
#   subnets = {
#     ...
#     privatelink = { address_prefix = "10.0.10.0/24" }
#   }
# (azurerm_subnet.private_endpoint_network_policies_enabled defaults false
# already in the underlying resource — no extra module input needed.)

# =====================================================
# EXAMPLE: private endpoint for one Key Vault instance ("secrets")
# =====================================================
# module "dns_keyvault" {
#   source = "../../modules/private-dns-zone"
#
#   zone_name           = "privatelink.vaultcore.azure.net"
#   resource_group_name = local.resource_group_name
#
#   vnet_links = {
#     "link-${local.name_prefix}" = module.networking[0].vnet_id
#   }
# }
#
# module "pe_keyvault_secrets" {
#   source = "../../modules/private-endpoints"
#
#   name                 = "pep-kv-${local.name_prefix}-secrets"
#   resource_group_name  = local.resource_group_name
#   location             = var.location
#   subnet_id            = module.networking[0].subnet_ids["privatelink"]
#
#   target_resource_id   = module.key_vault["secrets"].key_vault_id
#   subresource_names    = ["vault"]
#   private_dns_zone_ids = [module.dns_keyvault.zone_id]
#
#   tags = var.tags
# }
#
# Then tighten that instance's firewall in terraform.tfvars:
#   key_vaults = {
#     secrets = {
#       sku_name    = "standard"
#       enable_rbac = true
#       network_access = {
#         subnet_ids = ["<privatelink subnet ID once known, or reference module.networking[0].subnet_ids[\"privatelink\"] directly in this file instead>"]
#       }
#     }
#   }
#
# See modules/private-endpoints/README.md for the subresource_names / DNS
# zone name reference table for other services (Storage, SQL, Cosmos, etc.).
