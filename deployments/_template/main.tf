# Multi-Customer, Multi-Region Azure Infrastructure Deployment
#
# This is the main entry point, but resources are organized into separate files:
#
# - providers.tf          : Provider and Terraform configuration
# - backend.tf            : Remote state configuration
# - locals.tf             : Naming computed once, per CONVENTIONS.md #1
# - variables.tf          : All variable definitions
# - terraform.tfvars      : Variable values (this is what you edit!)
# - outputs.tf            : All outputs
#
# SUBSCRIPTIONS: landing-zone resources use the default azurerm provider;
# workload resources use azurerm.compute (see providers.tf).
#
# RESOURCE FILES (organized by category):
# - landing-zone.tf       : Shared RG, hub VNet, shared Key Vault (Landing Zone)
# - hub-spoke-peering.tf  : Hub <-> spoke VNet peering
# - core.tf               : Compute RG, spoke VNet (always needed)
# - storage.tf            : Storage accounts (multiple named instances)
# - key-vaults.tf         : Key Vaults (multiple named instances)
# - databases.tf          : SQL databases, Cosmos DB
# - private-connectivity.tf: Opt-in private endpoints, per resource (CONVENTIONS.md #2)
# - monitoring.tf         : Log Analytics (Landing Zone)
# - applications.tf       : Application Insights, Web Apps, Function Apps
# - containers.tf         : Container Registry and workload pull permissions
# - compute.tf            : Linux Virtual Machines
# - avd.tf                : Azure Virtual Desktop (enable_avd)
# - aca.tf                : Azure Container Apps (enable_aca)
# - front-door.tf         : Front Door + WAF (enable_front_door, Landing Zone)
#
# Read CONVENTIONS.md and MODULES_INDEX.md at the repo root before editing —
# they document the naming/network-access/diagnostics rules every module here
# follows, so you don't need to re-derive them from source.
#
# WHY THIS STRUCTURE?
# - Large deployments can have 100+ resources across 10+ resource types
# - Splitting by category keeps files manageable (< 100 lines each)
# - Team members can work on different files without conflicts
# - Easier to find and modify specific resource types
# - Git diffs show which category of resources changed
#
# TERRAFORM WORKFLOW:
# 1. Copy this _template folder for your customer
# 2. Edit terraform.tfvars with your configuration
# 3. Run: terraform init
# 4. Run: terraform plan (review changes)
# 5. Run: terraform apply
#
# Only implemented modules are called from this root. Candidate modules are
# staged in IMPLEMENTATION_ROADMAP.md and must not be added here until they
# have Terraform code and pass the validation gate.
#
# All module calls are in the respective resource files.
# This file serves as documentation only.
