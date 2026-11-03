# New Customer Onboarding Checklist

Quick reference checklist for deploying this template for a new customer in Azure DevOps.

## 📋 Pre-Deployment Planning

### Customer Information Gathering
- [ ] Customer name: _______________
- [ ] Short name (3-8 chars, lowercase): _______________
- [ ] Azure subscription ID: _______________
- [ ] Primary region: _______________
- [ ] Secondary region (if any): _______________
- [ ] Environment(s): dev / staging / prod
- [ ] Required modules identified
- [ ] Network address spaces planned (no overlap with existing customers)

### Azure DevOps Setup
- [ ] Azure DevOps organization selected: _______________
- [ ] Project selected or created: _______________
- [ ] Repository naming decided: `terraform-customer-{name}`

## 🔧 Azure DevOps Configuration (30 minutes)

### 1. Repository Setup
- [ ] Create new repository in Azure DevOps
  - Name: `terraform-customer-{customername}`
  - Visibility: Private
  - Initialize: Don't initialize (we'll push template)

### 2. Clone and Push Template
```bash
# Clone master template
git clone https://dev.azure.com/{org}/{project}/_git/terraform-azure-template-master
cd terraform-azure-template-master

# Change remote to new customer repo
git remote set-url origin https://dev.azure.com/{org}/{project}/_git/terraform-customer-{customername}

# Push to customer repo
git push -u origin main

# Add template as upstream (for future updates)
git remote add template https://dev.azure.com/{org}/{project}/_git/terraform-azure-template-master
git remote -v  # Verify remotes
```

### 3. Azure Service Principal
```bash
# Create service principal for customer
az login
az account set --subscription {subscription-id}

az ad sp create-for-rbac \
  --name "sp-terraform-{customer}-{env}" \
  --role "Contributor" \
  --scopes /subscriptions/{subscription-id}

# Save output:
# - appId (Client ID)
# - password (Client Secret)
# - tenant (Tenant ID)
```

- [ ] Service principal created
- [ ] Credentials saved securely (Key Vault or password manager)
- [ ] Service principal ID: _______________

### 4. Terraform State Storage Account
```bash
# Create resource group for state
az group create \
  --name "rg-terraform-state-{customer}" \
  --location {region}

# Create storage account
az storage account create \
  --name "stterraform{customer}001" \
  --resource-group "rg-terraform-state-{customer}" \
  --location {region} \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true

# Create container
az storage container create \
  --name tfstate \
  --account-name "stterraform{customer}001"

# Grant service principal access
az role assignment create \
  --assignee {service-principal-app-id} \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/{sub-id}/resourceGroups/rg-terraform-state-{customer}"
```

- [ ] Resource group created: _______________
- [ ] Storage account created: _______________
- [ ] Container created: `tfstate`
- [ ] Service principal has access

### 5. Azure DevOps Service Connection
1. Navigate to: **Project Settings** > **Service connections**
2. Click **New service connection**
3. Select **Azure Resource Manager**
4. Choose **Service principal (manual)**
5. Fill in details:
   - **Service connection name**: `azure-{customer}-{env}`
   - **Subscription ID**: {from Azure}
   - **Subscription Name**: {from Azure}
   - **Service Principal Id**: {appId from step 3}
   - **Service Principal Key**: {password from step 3}
   - **Tenant ID**: {from step 3}
6. Click **Verify**
7. Check **Grant access permission to all pipelines** (for convenience)
8. Click **Save**

- [ ] Service connection created and verified
- [ ] Name: _______________

### 6. Variable Group
1. Navigate to: **Pipelines** > **Library**
2. Click **+ Variable group**
3. Name: `{customer}-{env}-vars`
4. Add variables:

| Variable Name | Value | Secret? |
|--------------|-------|---------|
| `azureServiceConnection` | azure-{customer}-{env} | No |
| `customerName` | {customer} | No |
| `customerShortName` | {short} | No |
| `environmentName` | prod/dev/staging | No |
| `location` | eastus/westus/etc | No |
| `locationCode` | eus/wus/etc | No |
| `tfStateResourceGroup` | rg-terraform-state-{customer} | No |
| `tfStateStorageAccount` | stterraform{customer}001 | No |
| `tfStateContainerName` | tfstate | No |
| `tfStateKey` | {customer}-{region}-{env}.tfstate | No |
| `landing_zone_subscription_id` | {Landing Zone subscription ID: hub, shared Key Vault, Log Analytics, Front Door} | No |
| `compute_subscription_id` | {Compute subscription ID: spoke and workloads} | No |
| `approverEmail` | ops-team@company.com | No |

- [ ] Variable group created
- [ ] All variables added
- [ ] Variable group name: _______________

### 7. Environments
1. Navigate to: **Pipelines** > **Environments**
2. Create: `{customer}-dev`
   - No approvals needed
3. Create: `{customer}-staging`
   - Optional: Add approvers
4. Create: `{customer}-prod`
   - **Add approvers**: ops-team members
   - **Required approvers**: At least 1

- [ ] Dev environment created
- [ ] Staging environment created
- [ ] Prod environment created with approvers

## 📝 Customer Configuration (20 minutes)

### 8. Create Deployment Folder
```bash
cd deployments
cp -r _template {customer}-{region}-{env}
cd {customer}-{region}-{env}
```

### 9. Configure Variables
Edit `terraform.tfvars`:

```hcl
# Customer Information
customer_short_name = "{customer}"
environment         = "{env}"
location            = "{region}"
location_code       = "{code}"
landing_zone_subscription_id = "{sub-id}"
compute_subscription_id      = "{sub-id}"

# Module Control
enable_spoke_networking = true
enable_storage_account = true
enable_key_vault      = true
# ... enable required modules

# Networking
vnet_address_space = ["10.X.0.0/16"]  # Customer-specific

subnets = {
  gateway    = { address_prefix = "10.X.0.0/24" }
  appservice = { address_prefix = "10.X.1.0/24" }
  vms        = { address_prefix = "10.X.2.0/24" }
  data       = { address_prefix = "10.X.3.0/24" }
  mgmt       = { address_prefix = "10.X.255.0/24" }
}

# Tags
tags = {
  Customer    = "{Customer Name}"
  Environment = "{env}"
  ManagedBy   = "Terraform"
  CostCenter  = "{cost-center}"
}
```

- [ ] Deployment folder created
- [ ] `terraform.tfvars` configured
- [ ] Network addresses planned (no overlap)
- [ ] Required modules enabled

### 10. Configure Backend
Edit `backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-{customer}"
    storage_account_name = "stterraform{customer}001"
    container_name       = "tfstate"
    key                  = "{customer}-{region}-{env}.tfstate"
  }
}
```

- [ ] Backend configured with correct storage account
- [ ] State key is unique per deployment

### 11. Commit Configuration
```bash
git add .
git commit -m "Initial configuration for {customer}"
git push origin main
```

- [ ] Changes committed
- [ ] Changes pushed to Azure DevOps

## 🚀 Pipeline Setup (15 minutes)

### 12. Create Pipeline
1. Navigate to: **Pipelines** > **Pipelines**
2. Click **New pipeline**
3. Select **Azure Repos Git**
4. Select your customer repository
5. Choose **Existing Azure Pipelines YAML file**
6. Path: `/.azure-pipelines/terraform-deploy.yml`
7. Click **Continue**
8. **Don't run yet** - click dropdown next to Run > **Save**

- [ ] Pipeline created from YAML
- [ ] Pipeline saved (not run yet)

### 13. Configure Pipeline Variables
1. Edit the pipeline
2. Click **Variables** button (top right)
3. Add:
   - `customerName`: {customer}
   - `environmentName`: {env}
   - `location`: {region}
4. Click **Variable groups** tab
5. Link: `{customer}-{env}-vars`
6. Save

- [ ] Pipeline variables added
- [ ] Variable group linked

### 14. Branch Policies (Recommended for Production)
1. Navigate to: **Repos** > **Branches**
2. Click **...** on `main` branch
3. Select **Branch policies**
4. Configure:
   - ☑️ Require minimum number of reviewers: 1
   - ☑️ Check for linked work items: Optional
   - ☑️ Build validation: Add pipeline
   - ☑️ Status checks: Terraform Validate, Plan

- [ ] Branch policies configured
- [ ] Build validation added

## ✅ Validation & First Deployment (30 minutes)

### 15. Local Testing (Recommended)
```bash
cd deployments/{customer}-{region}-{env}

# Login to Azure
az login
az account set --subscription {subscription-id}

# Initialize
terraform init

# Validate
terraform validate

# Plan
terraform plan
```

- [ ] `terraform init` succeeds
- [ ] `terraform validate` succeeds
- [ ] `terraform plan` shows expected resources
- [ ] No errors in plan

### 16. Pipeline Test (Plan Only)
1. Go to **Pipelines** > Select your pipeline
2. Click **Run pipeline**
3. Review settings, click **Run**
4. Monitor:
   - ✅ Validate stage
   - ✅ Security Scan stage
   - ✅ Plan stage
5. Review plan output

- [ ] Pipeline runs successfully through Plan stage
- [ ] Plan output reviewed and approved
- [ ] No security issues found

### 17. First Apply
1. If plan looks good, proceed with apply:
   - Merge changes to `main` (if using PR workflow)
   - Or manually trigger pipeline
2. For production:
   - Wait for approval gate
   - Review plan one more time
   - Approve deployment
3. Monitor Apply stage
4. Verify resources in Azure Portal

- [ ] Apply completed successfully
- [ ] Resources verified in Azure Portal
- [ ] Terraform outputs captured
- [ ] No deployment errors

## 📚 Documentation

### 18. Customer Documentation
Create/update in repository:

**README.md** (customize for customer)
- [ ] Customer name and details
- [ ] Deployed regions and environments
- [ ] Architecture diagram (if available)
- [ ] Contact information
- [ ] Emergency procedures

**docs/architecture-decisions.md**
- [ ] Why certain modules enabled/disabled
- [ ] SKU selections and reasoning
- [ ] Network design decisions
- [ ] Security controls

- [ ] Customer README updated
- [ ] Architecture decisions documented

### 19. Update Tracking
Add to your master tracking system:

| Field | Value |
|-------|-------|
| Customer Name | {name} |
| Repo URL | {url} |
| Subscription ID | {id} |
| Primary Region | {region} |
| Environments | dev, staging, prod |
| Deployment Date | {date} |
| Contact | {contact} |

- [ ] Added to tracking system/spreadsheet

## 🎉 Post-Deployment

### 20. Communication
- [ ] Notify customer that infrastructure is deployed
- [ ] Provide outputs (endpoints, connection strings, etc.)
- [ ] Share documentation
- [ ] Schedule handoff/training session

### 21. Monitoring Setup
- [ ] Azure Monitor alerts configured
- [ ] Log Analytics workspace validated
- [ ] Diagnostic logs enabled
- [ ] Cost alerts configured

### 22. Access Control
- [ ] Customer team members added to Azure DevOps
- [ ] Azure RBAC roles assigned
- [ ] Key Vault access policies configured
- [ ] Emergency access documented

## 🔄 Ongoing Maintenance

### Monthly
- [ ] Review pipeline runs for failures
- [ ] Check for Terraform drift
- [ ] Review Azure costs
- [ ] Security scan results

### Quarterly
- [ ] Update Terraform version
- [ ] Update provider versions
- [ ] Apply template improvements
- [ ] Review and optimize costs

---

## ⏱️ Time Estimate

| Phase | Duration |
|-------|----------|
| Azure DevOps Configuration | 30 min |
| Customer Configuration | 20 min |
| Pipeline Setup | 15 min |
| Validation & Deployment | 30 min |
| **Total** | **~95 minutes** |

*Times may vary based on complexity and number of modules deployed.*

## 🆘 Troubleshooting

### Common Issues

**Pipeline fails at Init**
- Verify service connection works
- Check storage account access
- Ensure backend.tf is configured correctly

**Plan shows unexpected resources**
- Check for manual Azure Portal changes
- Review terraform.tfvars values
- Verify module enable flags

**Apply times out**
- Increase pipeline timeout setting
- Check Azure quotas
- Review resource dependencies

**State locking errors**
- Check if another deployment is running
- Verify storage account is accessible
- Manual unlock: `terraform force-unlock {lock-id}`

---

## 📞 Support Contacts

| Issue Type | Contact |
|------------|---------|
| Template Issues | template-team@company.com |
| Azure DevOps | devops-admin@company.com |
| Azure Access | azure-admins@company.com |
| Customer Questions | account-manager@company.com |

---

**Template Version**: 1.0  
**Last Updated**: {date}  
**Maintained By**: Infrastructure Team
