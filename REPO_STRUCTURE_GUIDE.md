# Repository Structure Per Customer

This document explains the recommended repository structure when deploying this template for multiple customers.

## 🏢 Multi-Customer Strategy

### Recommended: One Repository Per Customer

```
Azure DevOps Organization
│
├── 📦 terraform-azure-template-master (Source Template)
│   └── Purpose: Master template that you maintain and improve
│
├── 📦 terraform-customer-contoso
│   ├── deployments/
│   │   ├── contoso-eastus-dev/
│   │   ├── contoso-eastus-staging/
│   │   └── contoso-eastus-prod/
│   ├── modules/ (from template)
│   └── .azure-pipelines/
│
├── 📦 terraform-customer-fabrikam
│   ├── deployments/
│   │   ├── fabrikam-westus-dev/
│   │   └── fabrikam-westus-prod/
│   ├── modules/ (from template)
│   └── .azure-pipelines/
│
└── 📦 terraform-customer-northwind
    ├── deployments/
    │   ├── northwind-eastus-prod/
    │   └── northwind-westeurope-prod/
    ├── modules/ (from template)
    └── .azure-pipelines/
```

## ✅ Benefits of This Approach

| Benefit | Description |
|---------|-------------|
| **Complete Isolation** | Each customer has separate code history, state, and credentials |
| **Security** | Customer-specific RBAC and service principals |
| **Compliance** | Independent audit trails per customer |
| **Flexibility** | Each customer can have custom modules or configurations |
| **No Cross-Contamination** | Zero risk of deploying to wrong customer |
| **Independent Pipelines** | Customer-specific deployment schedules |

## 🔄 Template Propagation

### How to Keep Customer Repos Updated

Each customer repository tracks the template as an "upstream" remote:

```bash
# In customer repository
cd terraform-customer-contoso

# Add template as upstream
git remote add template https://dev.azure.com/{org}/{project}/_git/terraform-azure-template-master

# Fetch template updates
git fetch template

# Merge template improvements (selectively)
git merge template/main
# or cherry-pick specific updates
git cherry-pick {commit-hash}

# Push to customer repo
git push origin main
```

### Update Workflow

```
Template Repo (Master)
    │
    │ 1. New feature added
    │ 2. Bug fixed
    │ 3. Module improved
    │
    ├─────────────────┬─────────────────┬────────────────
    ▼                 ▼                 ▼
Customer A        Customer B        Customer C
    │                 │                 │
    │ Fetch updates   │ Fetch updates   │ Fetch updates
    │ Review changes  │ Review changes  │ Review changes
    │ Test in dev     │ Test in dev     │ Test in dev
    │ Merge           │ Merge           │ Merge
    │ Deploy          │ Deploy          │ Deploy
```

## 📁 Customer Repository Contents

### What Gets Customized Per Customer

```
terraform-customer-contoso/
│
├── deployments/                    ← CUSTOMER-SPECIFIC
│   ├── contoso-eastus-dev/
│   │   ├── terraform.tfvars       ← Customer values
│   │   ├── backend.tf             ← Customer state storage
│   │   └── [template files]
│   ├── contoso-eastus-staging/
│   └── contoso-eastus-prod/
│
├── modules/                        ← FROM TEMPLATE (rarely modified)
│   ├── networking/
│   ├── storage-account/
│   └── [all modules]
│
├── .azure-pipelines/               ← CUSTOMER-SPECIFIC
│   └── terraform-deploy.yml       ← Customer pipeline config
│
├── docs/                           ← CUSTOMER-SPECIFIC
│   ├── architecture-decisions.md
│   └── runbooks/
│
├── README.md                       ← CUSTOMER-SPECIFIC
├── .gitignore                      ← FROM TEMPLATE
└── [documentation files]           ← FROM TEMPLATE
```

## 🔐 Isolation Points

### What's Separate Per Customer

| Resource | Isolation Level |
|----------|----------------|
| **Git Repository** | Completely separate per customer |
| **Azure Subscription** | Typically separate (or separate resource groups) |
| **Service Principal** | Dedicated per customer + environment |
| **Terraform State** | Separate storage account per customer |
| **Variable Groups** | Per customer + environment |
| **Pipelines** | Per customer repository |
| **Secrets** | Per customer Key Vault |

## 🎯 Deployment Flow Per Customer

### From Template to Production

```
1. Template Repository
   └── Master template with all modules
       │
       │ Copy/Clone
       ▼
2. Customer Repository
   └── Fresh copy of template
       │
       │ Customize deployments/
       ▼
3. Configure Azure DevOps
   ├── Service Connection
   ├── Variable Groups
   ├── Pipeline
   └── Environments
       │
       │ Run Pipeline
       ▼
4. Deploy to Azure
   ├── Dev Environment
   ├── Staging Environment
   └── Production Environment
```

## 📊 Comparison: Repository Strategies

### ❌ Not Recommended: One Repo, Multiple Customers

```
terraform-multi-customer/
├── deployments/
│   ├── contoso-eastus/
│   ├── fabrikam-westus/
│   └── northwind-eastus/
└── modules/
```

**Problems:**
- ❌ Shared Git history across customers
- ❌ Risk of accidental cross-customer changes
- ❌ Complex pipeline logic to route to correct customer
- ❌ Difficult to manage customer-specific permissions
- ❌ One bad commit affects all customers
- ❌ Shared state storage (security risk)

### ✅ Recommended: Separate Repos Per Customer

```
terraform-customer-contoso/
├── deployments/contoso-eastus/
└── modules/

terraform-customer-fabrikam/
├── deployments/fabrikam-westus/
└── modules/
```

**Benefits:**
- ✅ Complete isolation
- ✅ Independent version control
- ✅ Simple pipelines
- ✅ Easy RBAC management
- ✅ Customer-specific rollback
- ✅ Separate state storage

## 🛠️ State Management

### Each Customer Gets Own State Storage

```
Customer A:
  Resource Group: rg-terraform-state-contoso
  Storage Account: stterraformcontoso001
  Container: tfstate
  State File: contoso-eastus-prod.tfstate

Customer B:
  Resource Group: rg-terraform-state-fabrikam
  Storage Account: stterraformfabrikam001
  Container: tfstate
  State File: fabrikam-westus-prod.tfstate
```

**Why?**
- Security: No cross-customer state access
- Compliance: Independent audit trails
- Reliability: Failure in one doesn't affect others
- Performance: No locking conflicts between customers

## 🔄 Maintenance Workflow

### Weekly: Monitor Customer Deployments
```bash
# Check all customer pipelines
for repo in customer-*; do
  echo "Checking $repo..."
  # Review last pipeline run
  # Check for failures
done
```

### Monthly: Propagate Template Improvements
```bash
# In template repo
git log --since="1 month ago"  # Review changes

# In each customer repo
git fetch template
git log template/main  # Review what's new
git cherry-pick {useful-commits}
git push
```

### Quarterly: Update Dependencies
- Terraform version updates
- Provider version updates
- Security patches
- Module improvements

## 📋 Quick Reference

### Initial Setup (Per Customer)
1. ✅ Clone template repo
2. ✅ Create customer repo in Azure DevOps
3. ✅ Push template to customer repo
4. ✅ Add template as upstream remote
5. ✅ Create customer deployments
6. ✅ Configure Azure DevOps resources
7. ✅ Deploy

### Ongoing Maintenance
1. ✅ Improve template repo
2. ✅ Fetch updates in customer repos
3. ✅ Test updates in dev
4. ✅ Deploy to staging/prod
5. ✅ Repeat

## 🎓 Team Workflow

### Template Team
- Maintains master template
- Adds new modules
- Fixes bugs
- Updates documentation
- Reviews PRs from customer teams

### Customer Team
- Manages customer-specific repos
- Fetches template updates
- Tests and deploys changes
- Handles customer-specific requests
- Escalates generic issues to template team

## 📈 Scaling to Many Customers

As you onboard more customers:

1. **Automate Onboarding**
   - Create scripts to set up new customer repos
   - Automate Azure DevOps configuration
   - Template variable groups

2. **Central Tracking**
   - Maintain spreadsheet of all customer repos
   - Track Terraform versions
   - Monitor deployment health

3. **Standardize Processes**
   - Use the NEW_CUSTOMER_CHECKLIST.md
   - Document lessons learned
   - Update template based on feedback

4. **Consider Hub-Spoke**
   - Template repo = Hub
   - Customer repos = Spokes
   - Automate updates with scripts

## 🆘 Troubleshooting

### Issue: Customer repo out of sync with template

**Solution:**
```bash
cd terraform-customer-{name}
git fetch template
git merge template/main
# Resolve conflicts if any
git push
```

### Issue: Need to rollback customer deployment

**Solution:**
```bash
# In customer repo
git log  # Find previous good commit
git revert {bad-commit-hash}
git push
# Re-run pipeline
```

### Issue: Customer needs custom module

**Options:**
1. Add to template if generic enough
2. Create customer-specific module in their repo
3. Override module in customer deployment folder

## Summary

**Best Practice**: One Azure DevOps repository per customer with isolated state, credentials, and pipelines. Template improvements propagate via git remotes.

This provides maximum security, isolation, and flexibility while maintaining centralized template improvements.
