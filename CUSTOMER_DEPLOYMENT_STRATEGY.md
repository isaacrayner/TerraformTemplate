# Customer Deployment Strategy - Azure DevOps

This document outlines the recommended approach for deploying this Terraform template for multiple customers using Azure DevOps.

## 🎯 Strategy: One Repository Per Customer

### Recommended Approach
Create a **separate Azure DevOps repository for each customer**. This provides complete isolation and independent lifecycle management.

```
Azure DevOps Organization: YourCompany
├── Project: Infrastructure (or per-customer projects)
│   ├── Repo: terraform-customer-contoso
│   ├── Repo: terraform-customer-fabrikam
│   ├── Repo: terraform-customer-adventureworks
│   └── Repo: terraform-customer-northwind
```

### Why This Approach?

✅ **Complete Isolation**
- Separate code history per customer
- No risk of accidental cross-customer changes
- Independent state management
- Isolated credentials and secrets

✅ **Security & Compliance**
- Customer-specific RBAC and permissions
- Separate service principals per customer
- Independent audit trails
- Easier compliance reporting

✅ **Operational Benefits**
- Customer-specific CI/CD pipelines
- Independent deployment schedules
- Separate approval workflows
- Customer-specific branching strategies

✅ **Version Control**
- Track changes per customer independently
- Customer-specific feature branches
- Easier rollback per customer
- No merge conflicts between customers

## 📋 Initial Setup Process

### Step 1: Create Template Repository (One Time)

This is the **source template** repository that you maintain and improve:

```bash
# Create a "template" or "master" repository in Azure DevOps
Repo Name: terraform-azure-template-master
Description: Master Terraform template for Azure deployments
```

**Purpose**: 
- Single source of truth for template improvements
- Version-controlled template evolution
- Testing ground for new modules
- Documentation updates

### Step 2: Deploy Template for New Customer

When onboarding a new customer:

#### Option A: Fork/Clone Approach (Recommended)

1. **Create new customer repository**
   ```bash
   # In Azure DevOps
   Repo Name: terraform-customer-{customername}
   Description: Azure Infrastructure for {Customer Name}
   ```

2. **Initialize from template**
   ```bash
   # Clone the template
   git clone https://dev.azure.com/yourorg/Infrastructure/_git/terraform-azure-template-master
   cd terraform-azure-template-master
   
   # Change remote to customer repo
   git remote set-url origin https://dev.azure.com/yourorg/Infrastructure/_git/terraform-customer-contoso
   
   # Push to customer repo
   git push -u origin main
   ```

3. **Customer-specific setup**
   ```bash
   cd deployments
   cp -r _template contoso-eastus
   cd contoso-eastus
   
   # Edit terraform.tfvars with customer details
   # Commit customer-specific configuration
   git add .
   git commit -m "Initial deployment configuration for Contoso"
   git push
   ```

#### Option B: Import/Export (Alternative)

1. Export template repo as ZIP
2. Import into new customer repo in Azure DevOps
3. Configure customer-specific settings

### Step 3: Configure Azure DevOps Resources

For each customer repository, set up:

#### A. Service Connection
```yaml
# Create Azure Resource Manager service connection
Name: azure-{customer}-{environment}
Subscription: {Customer Azure Subscription}
Resource Group: (optional scope)
Service Principal: Dedicated SP per customer
```

#### B. Variable Groups
```yaml
# Library > Variable Groups
Group Name: {customer}-{environment}-vars

Variables:
  - AZURE_SUBSCRIPTION_ID
  - CUSTOMER_SHORT_NAME
  - ENVIRONMENT
  - LOCATION
  - TF_STATE_RESOURCE_GROUP
  - TF_STATE_STORAGE_ACCOUNT
  - TF_STATE_CONTAINER_NAME
```

#### C. Secure Files
- Service principal certificates (if using)
- SSH keys for private module registries
- Custom CA certificates

## 🔄 Keeping Template in Sync

### Challenge
How do you propagate template improvements to customer repositories?

### Solution: Git Remote Tracking

Each customer repo can track the template repo as an upstream remote:

```bash
# In customer repository
cd terraform-customer-contoso

# Add template as upstream remote
git remote add template https://dev.azure.com/yourorg/Infrastructure/_git/terraform-azure-template-master

# Fetch template updates
git fetch template

# Review what changed in template
git log template/main

# Merge template updates (when ready)
git merge template/main

# Or cherry-pick specific commits
git cherry-pick <commit-hash>

# Push updates to customer repo
git push origin main
```

### Update Workflow

1. **Make improvements in template repo**
   ```bash
   # In terraform-azure-template-master
   # Add new module or fix bug
   git commit -m "feat: add Azure Firewall module"
   git push
   ```

2. **Selectively apply to customer repos**
   ```bash
   # In each customer repo
   git fetch template
   git cherry-pick <commit-hash>  # Pick specific improvements
   git push
   ```

3. **Test before deploying**
   - Always run `terraform plan` after merging
   - Use feature branches for major updates
   - Test in dev/staging environments first

## 🏗️ Repository Structure Per Customer

```
terraform-customer-contoso/
├── .azure-pipelines/           # Customer-specific pipelines
│   ├── pipeline-dev.yml
│   ├── pipeline-staging.yml
│   └── pipeline-prod.yml
├── modules/                    # Shared modules (from template)
│   ├── networking/
│   ├── storage-account/
│   └── [all modules]
├── deployments/                # Customer-specific deployments
│   ├── contoso-eastus-dev/
│   ├── contoso-eastus-staging/
│   ├── contoso-eastus-prod/
│   └── contoso-westeurope-prod/
├── docs/                       # Customer-specific documentation
│   └── architecture-decisions.md
├── .gitignore
└── README.md                   # Customized for this customer
```

## 🔐 Security Considerations

### Service Principals

Create **dedicated service principal per customer**:

```bash
# Create SP for customer
az ad sp create-for-rbac --name "sp-terraform-contoso" \
  --role "Contributor" \
  --scopes /subscriptions/{subscription-id}

# Store credentials in Azure DevOps
# Library > Variable Groups > contoso-prod-vars
# Mark as secret variables
```

### State Management

Each customer should have **isolated Terraform state**:

```hcl
# deployments/contoso-eastus-prod/backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-contoso"
    storage_account_name = "stterraformcontoso001"
    container_name       = "tfstate"
    key                  = "contoso-eastus-prod.tfstate"
  }
}
```

**Important**: Never share state storage accounts between customers!

### Secrets Management

- **Azure Key Vault per customer** for secrets
- **Variable Groups** for non-sensitive configuration
- **Secure Files** for certificates
- Never commit `terraform.tfvars` with real values

## 📊 Azure DevOps Pipeline Example

Create `.azure-pipelines/terraform-pipeline.yml` in each customer repo:

```yaml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - deployments/*
      - modules/*

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: contoso-prod-vars
  - name: deploymentPath
    value: 'deployments/contoso-eastus-prod'

stages:
  - stage: Validate
    jobs:
      - job: TerraformValidate
        steps:
          - task: TerraformInstaller@0
            inputs:
              terraformVersion: '1.5.0'
          
          - task: TerraformTaskV4@4
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              workingDirectory: '$(deploymentPath)'
              backendServiceArm: 'azure-contoso-prod'
              backendAzureRmResourceGroupName: '$(TF_STATE_RESOURCE_GROUP)'
              backendAzureRmStorageAccountName: '$(TF_STATE_STORAGE_ACCOUNT)'
              backendAzureRmContainerName: '$(TF_STATE_CONTAINER_NAME)'
              backendAzureRmKey: 'contoso-eastus-prod.tfstate'
          
          - task: TerraformTaskV4@4
            displayName: 'Terraform Validate'
            inputs:
              provider: 'azurerm'
              command: 'validate'
              workingDirectory: '$(deploymentPath)'

  - stage: Plan
    dependsOn: Validate
    jobs:
      - job: TerraformPlan
        steps:
          - task: TerraformTaskV4@4
            displayName: 'Terraform Plan'
            inputs:
              provider: 'azurerm'
              command: 'plan'
              workingDirectory: '$(deploymentPath)'
              environmentServiceNameAzureRM: 'azure-contoso-prod'

  - stage: Apply
    dependsOn: Plan
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: TerraformApply
        environment: 'contoso-production'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: TerraformTaskV4@4
                  displayName: 'Terraform Apply'
                  inputs:
                    provider: 'azurerm'
                    command: 'apply'
                    workingDirectory: '$(deploymentPath)'
                    environmentServiceNameAzureRM: 'azure-contoso-prod'
                    commandOptions: '-auto-approve'
```

## 🔄 Workflow Best Practices

### Branching Strategy

```
main (protected)
├── feature/add-firewall-module
├── feature/update-networking
└── hotfix/fix-storage-encryption
```

**Rules**:
- `main` branch is protected, requires PR
- All changes via pull requests
- Run `terraform plan` in PR validation
- Require approval before merge
- Auto-deploy from `main` (optional)

### Development Workflow

1. **Create feature branch**
   ```bash
   git checkout -b feature/add-sql-database
   ```

2. **Make changes**
   ```bash
   # Enable SQL module
   # Edit deployments/contoso-eastus-prod/terraform.tfvars
   enable_sql_database = true
   ```

3. **Test locally**
   ```bash
   cd deployments/contoso-eastus-prod
   terraform init
   terraform plan
   ```

4. **Create pull request**
   - PR includes `terraform plan` output
   - Reviewers approve changes
   - Pipeline runs validation

5. **Merge and deploy**
   - Merge to `main`
   - Pipeline auto-deploys (if configured)
   - Or manual approval gate

## 📋 Customer Onboarding Checklist

- [ ] Create new Azure DevOps repository: `terraform-customer-{name}`
- [ ] Clone template repository
- [ ] Push to new customer repository
- [ ] Create customer deployment folders in `deployments/`
- [ ] Configure `terraform.tfvars` for customer
- [ ] Create Azure service connection in Azure DevOps
- [ ] Create variable group for customer
- [ ] Set up Azure storage account for Terraform state
- [ ] Configure `backend.tf` with state storage details
- [ ] Create Azure DevOps pipeline from YAML
- [ ] Set up branch protection policies on `main`
- [ ] Create environments in Azure DevOps (dev, staging, prod)
- [ ] Configure approval gates for production
- [ ] Test pipeline with `terraform plan`
- [ ] Document customer-specific architecture decisions
- [ ] Add customer repo to your tracking list

## 🎯 Maintenance Strategy

### Template Updates

**Monthly**: Review template repo for improvements
- New module additions
- Security patches
- Terraform version updates
- Provider updates

**Quarterly**: Update customer repos
- Selectively apply template improvements
- Test in dev environment first
- Roll out to staging, then production

### Customer-Specific Changes

Keep customer modifications in `deployments/` folder:
- ✅ Custom `terraform.tfvars` values
- ✅ Customer-specific pipeline configurations
- ✅ Environment-specific overrides
- ❌ Avoid modifying shared modules directly

If a customer needs a module change:
1. Consider if it should be in the template (generic improvement)
2. If customer-specific, create override in deployment folder
3. If generic, update template and propagate to other customers

## 📚 Documentation Requirements

Each customer repository should include:

1. **README.md** - Customized for customer
   - Customer name and subscription details
   - Deployed regions and environments
   - Contact information
   - Emergency procedures

2. **Architecture Decision Records (ADRs)**
   - Why certain modules are enabled/disabled
   - SKU selections and reasoning
   - Network design decisions
   - Security controls implemented

3. **Runbooks**
   - Deployment procedures
   - Disaster recovery steps
   - Troubleshooting guides
   - Contact escalation paths

## 🚨 Common Pitfalls to Avoid

❌ **Don't**: Share state storage accounts between customers
✅ **Do**: Create isolated state storage per customer

❌ **Don't**: Use one repo with customer folders
✅ **Do**: Use separate repos per customer

❌ **Don't**: Share service principals across customers
✅ **Do**: Create dedicated service principals

❌ **Don't**: Hard-code customer values in modules
✅ **Do**: Keep modules generic, use variables

❌ **Don't**: Commit secrets to Git
✅ **Do**: Use Azure Key Vault and Variable Groups

❌ **Don't**: Auto-deploy to production without approvals
✅ **Do**: Use manual approval gates

## 🔍 Monitoring and Governance

### Track Customer Deployments

Maintain a master spreadsheet/database:
- Customer name
- Repository URL
- Azure subscription ID
- Deployed regions
- Last deployment date
- Terraform version
- Template version/commit

### Regular Audits

**Weekly**: Check pipeline status across customers
**Monthly**: Review security configurations
**Quarterly**: Update Terraform and provider versions
**Annually**: Review architecture and cost optimization

## 📞 Support Model

### Template Support
- Central team maintains template repository
- Bug fixes and improvements propagate to customers
- Document breaking changes carefully

### Customer-Specific Support
- Each customer team manages their repository
- Customer-specific issues stay in customer repo
- Escalate generic issues to template team

## 🎓 Training Team Members

New team members should:
1. Clone template repository locally
2. Review module documentation
3. Understand variable structure
4. Practice creating test deployments
5. Learn branching and PR workflow
6. Understand state management
7. Review security best practices

## Summary

**Best Practice**: One Azure DevOps repository per customer with isolated state, credentials, and pipelines. Track template repository as upstream remote for selective updates.

This approach provides maximum isolation, security, and flexibility while maintaining the ability to propagate improvements across customers.
