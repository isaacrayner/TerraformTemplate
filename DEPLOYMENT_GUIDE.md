# Deployment Guide

Complete guide for deploying infrastructure for new customers using this template.

## Prerequisites

1. **Terraform** installed (>= 1.5.0)
   ```bash
   winget install Hashicorp.Terraform
   ```

2. **Azure CLI** installed and authenticated
   ```bash
   winget install Microsoft.AzureCLI
   az login
   ```

3. **Access** to Azure subscription with appropriate permissions

## Step-by-Step Deployment

### Step 1: Create New Customer Deployment

Navigate to deployments folder and copy the template:

```bash
cd deployments
cp -r _template contoso-eastus
cd contoso-eastus
```

**Naming Convention**: `{customer-name}-{region}` (e.g., `contoso-eastus`, `fabrikam-westeurope`)

### Step 2: Configure Variables

Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your customer-specific values:

```hcl
# Core Settings
customer_short_name = "contoso"     # 3-8 lowercase letters
environment         = "prod"
location            = "eastus"
location_code       = "eus"
subscription_id     = "your-subscription-id"

# Enable required modules
enable_networking      = true
enable_storage_account = true
enable_key_vault       = true

# Networking configuration
vnet_address_space = ["10.0.0.0/16"]
subnets = {
  gateway    = { address_prefix = "10.0.0.0/24" }
  appservice = { address_prefix = "10.0.1.0/24" }
  vms        = { address_prefix = "10.0.2.0/24" }
  data       = { address_prefix = "10.0.3.0/24" }
  mgmt       = { address_prefix = "10.0.255.0/24" }
}
```

### Step 3: Initialize Terraform

```bash
terraform init
```

This will:
- Download required providers (azurerm)
- Initialize the backend
- Prepare the working directory

### Step 4: Validate Configuration

```bash
terraform validate
```

Fix any syntax errors or validation issues.

### Step 5: Review the Plan

```bash
terraform plan
```

Review the planned changes carefully:
- Resource names match the naming convention
- All required resources are included
- No unexpected changes

**Tip**: Save the plan for review:
```bash
terraform plan -out=tfplan
```

### Step 6: Apply Configuration

```bash
terraform apply
```

Or apply the saved plan:
```bash
terraform apply tfplan
```

Type `yes` when prompted to confirm.

### Step 7: Verify Deployment

```bash
terraform output
```

Check the Azure Portal to verify resources were created correctly.

## Multi-Region Deployment

### Scenario: Deploy to East US and West Europe

#### Option 1: Separate Deployment Folders

```bash
# Create first region
cd deployments
cp -r _template contoso-eastus
cd contoso-eastus
# Configure terraform.tfvars for East US
terraform init
terraform apply

# Create second region
cd ..
cp -r _template contoso-westeurope
cd contoso-westeurope
# Configure terraform.tfvars for West Europe
terraform init
terraform apply
```

#### Option 2: Using Terraform Workspaces

```bash
cd deployments/contoso-eastus

# Create workspaces
terraform workspace new eastus
terraform workspace new westeurope

# Deploy to East US
terraform workspace select eastus
# Update terraform.tfvars for East US
terraform apply

# Deploy to West Europe
terraform workspace select westeurope
# Update terraform.tfvars for West Europe
terraform apply
```

**Recommendation**: Use separate folders for better isolation and clarity.

## Adding Optional Modules

To add optional modules like VMs or App Services:

1. Edit `terraform.tfvars` and set the flag to `true`:
   ```hcl
   enable_virtual_machine = true
   ```

2. Uncomment the relevant module in `main.tf`

3. Configure module-specific variables in `terraform.tfvars`

4. Run `terraform plan` to review changes

5. Run `terraform apply` to deploy

## Configuring Remote State Storage

For production deployments, use remote state storage:

### Step 1: Create State Storage Account

```bash
# Set variables
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="sttfstatecontoso001"  # Must be globally unique
CONTAINER="tfstate"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2

# Create blob container
az storage container create \
  --name $CONTAINER \
  --account-name $STORAGE_ACCOUNT
```

### Step 2: Configure Backend

Edit `backend.tf` and uncomment the backend block:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatecontoso001"
    container_name       = "tfstate"
    key                  = "contoso-eastus.tfstate"
  }
}
```

### Step 3: Migrate State

```bash
terraform init -reconfigure
```

## Common Module Patterns

### Pattern 1: Basic Landing Zone
Minimal infrastructure for a new customer:
```hcl
enable_networking      = true
enable_storage_account = true
enable_key_vault       = true
```

### Pattern 2: VM-Based Workload
Infrastructure with virtual machines:
```hcl
enable_networking      = true
enable_storage_account = true
enable_key_vault       = true
enable_virtual_machine = true
```

### Pattern 3: App Service with Caching
Modern web application infrastructure:
```hcl
enable_networking      = true
enable_storage_account = true
enable_key_vault       = true
enable_app_service     = true
enable_redis_cache     = true
```

### Pattern 4: Multi-Region with Front Door
Global, highly available infrastructure:
```hcl
# In each region deployment
enable_networking      = true
enable_storage_account = true
enable_key_vault       = true
enable_app_service     = true

# In one deployment (typically first region)
enable_front_door      = true
```

## Customizing Network Configuration

### Custom Address Spaces

For different network sizes, adjust the VNet address space:

```hcl
# Small network (254 IPs)
vnet_address_space = ["10.0.0.0/24"]

# Medium network (4096 IPs) - Default
vnet_address_space = ["10.0.0.0/20"]

# Large network (65536 IPs)
vnet_address_space = ["10.0.0.0/16"]
```

### Custom Subnets

Adjust subnets based on workload requirements:

```hcl
subnets = {
  frontend = {
    address_prefix = "10.0.10.0/24"  # 254 IPs for frontend
  }
  backend = {
    address_prefix = "10.0.20.0/23"  # 510 IPs for backend (larger)
  }
  database = {
    address_prefix = "10.0.30.0/24"  # 254 IPs for database
  }
  management = {
    address_prefix = "10.0.255.0/26" # 62 IPs for management (smaller)
  }
}
```

## Updating Existing Deployments

To modify an existing deployment:

1. Update `terraform.tfvars` with new values
2. Run `terraform plan` to preview changes
3. Review changes carefully
4. Run `terraform apply` to apply changes

### Adding a New Module

1. Set the enable flag to `true` in `terraform.tfvars`
2. Uncomment the module in `main.tf`
3. Configure module variables
4. Run `terraform plan` and `terraform apply`

### Removing Resources

**Warning**: Removing resources will delete them from Azure!

1. Set the enable flag to `false` in `terraform.tfvars`
2. Run `terraform plan` to review deletions
3. Run `terraform apply` to remove resources

## Troubleshooting

### Issue: Module Not Found

**Error**: `Module not found: ../../modules/networking`

**Solution**: Ensure you're in a deployment folder and the path to modules is correct.

### Issue: Resource Already Exists

**Error**: `Resource already exists in Azure`

**Solution**: Import the existing resource or use a different name:
```bash
terraform import module.networking[0].azurerm_resource_group.network /subscriptions/{sub-id}/resourceGroups/{rg-name}
```

### Issue: Naming Validation Error

**Error**: `Customer short name must be 3-8 lowercase letters`

**Solution**: Ensure `customer_short_name` follows the rules (3-8 lowercase letters, no numbers or special characters).

### Issue: Subscription Not Found

**Error**: `Subscription not found`

**Solution**: 
1. Verify subscription ID in `terraform.tfvars`
2. Ensure you're logged in: `az login`
3. Set the subscription: `az account set --subscription {subscription-id}`

## Best Practices

1. **Always run `terraform plan`** before `apply`
2. **Use remote state** for production deployments
3. **Version control** everything except `terraform.tfvars`
4. **Tag all resources** appropriately for cost tracking
5. **Use separate folders** for different regions
6. **Follow naming conventions** consistently
7. **Document custom configurations** in deployment folder
8. **Review outputs** after deployment
9. **Enable only needed modules** to control costs
10. **Test in dev/staging** before production

## Getting Help

- **Full Documentation**: [.github/copilot-instructions.md](../.github/copilot-instructions.md)
- **Module Documentation**: Check README.md in each module folder
- **GitHub Copilot**: Ask questions - it understands this template structure
- **Azure Documentation**: https://learn.microsoft.com/azure/

## Next Steps

After successful deployment:

1. Configure RBAC permissions for Key Vault
2. Set up diagnostic logging and monitoring
3. Configure backup policies
4. Implement Azure Policy compliance
5. Set up CI/CD pipelines for infrastructure updates
6. Document any custom configurations
7. Train team on the template structure
