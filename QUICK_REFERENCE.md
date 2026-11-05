# Quick Reference Card

## 🚀 New Customer Deployment (5 Steps)

```
1. COPY        →  2. CONFIGURE     →  3. INIT       →  4. PLAN       →  5. APPLY
   Template         Variables            Terraform        Review           Deploy
```

### Detailed Commands

```bash
# 1. Copy template
cd deployments && cp -r _template contoso-eastus && cd contoso-eastus

# 2. Configure
cp terraform.tfvars.example terraform.tfvars
# Edit: customer_short_name, landing_zone_subscription_id, compute_subscription_id, location, location_code

# 3. Initialize
terraform init

# 4. Plan
terraform plan

# 5. Apply
terraform apply
```

## 📋 Essential Variables

```hcl
# Always Required
customer_short_name = "contoso"   # 3-8 lowercase letters
environment         = "prod"      # prod, dev, staging, uat, test
location            = "eastus"    # Azure region
location_code       = "eus"       # 2-4 letter code
landing_zone_subscription_id = "xxx..."  # Hub, shared Key Vault, Log Analytics
compute_subscription_id      = "xxx..."  # Spoke and workloads

# Module Control (Boolean)
enable_spoke_networking = true     # Core - always true
enable_storage_account = true     # Core - almost always true
enable_key_vault       = true     # Core - almost always true
enable_virtual_machine = false    # Optional
enable_app_service     = false    # Optional
enable_front_door      = false    # Optional - multi-region
enable_redis_cache     = false    # Optional
```

## 🏷️ Naming Convention Cheat Sheet

| Resource | Pattern | Example |
|----------|---------|---------|
| VNet | `vnet-{c}-{e}-{r}-{i}` | `vnet-contoso-prod-eus-001` |
| Storage | `st{c}{e}{r}{i}` | `stcontosoprodeus001` |
| Key Vault | `kv-{c}-{e}-{r}-{i}` | `kv-contoso-prod-eus-001` |
| VM | `vm-{c}-{e}-{r}-{i}` | `vm-contoso-prod-eus-001` |
| App Service | `app-{c}-{e}-{r}-{i}` | `app-contoso-prod-eus-001` |
| Front Door | `fd-{c}-{e}-global-{i}` | `fd-contoso-prod-global-001` |
| Redis | `redis-{c}-{e}-{r}-{i}` | `redis-contoso-prod-eus-001` |

Legend: `{c}` = customer, `{e}` = environment, `{r}` = region, `{i}` = instance

## 🌍 Common Region Codes

| Region | Code | Region | Code |
|--------|------|--------|------|
| East US | `eus` | West Europe | `weu` |
| West US | `wus` | North Europe | `neu` |
| Central US | `cus` | UK South | `uks` |
| East US 2 | `eus2` | Southeast Asia | `sea` |

**Full list**: See [REGION_CODES.md](REGION_CODES.md)

## 🔧 Common Patterns

### Pattern 1: Basic Landing Zone
```hcl
enable_spoke_networking = true
enable_storage_account = true
enable_key_vault       = true
```
**Use for**: New customer setup, foundation infrastructure

### Pattern 2: Web Application
```hcl
enable_spoke_networking = true
enable_storage_account = true
enable_key_vault       = true
enable_app_service     = true
enable_redis_cache     = true
```
**Use for**: Modern web applications with caching

### Pattern 3: VM Workload
```hcl
enable_spoke_networking = true
enable_storage_account = true
enable_key_vault       = true
enable_virtual_machine = true
```
**Use for**: Traditional VM-based applications

### Pattern 4: Multi-Region
```bash
# Region 1
cp -r _template contoso-eastus
# Set: location=eastus, location_code=eus

# Region 2
cp -r _template contoso-westeurope
# Set: location=westeurope, location_code=weu, enable_front_door=true
```
**Use for**: Global applications with high availability

## 📂 Directory Structure

```
TerraformTemplate/
├── modules/              ← Reusable modules (don't modify often)
│   ├── networking/       ← VNet, Subnets, NSGs
│   ├── storage-account/  ← Azure Storage
│   ├── key-vault/        ← Azure Key Vault
│   ├── virtual-machine/  ← Azure VMs
│   ├── app-service/      ← Azure App Service
│   ├── front-door/       ← Azure Front Door
│   └── redis-cache/      ← Azure Redis
├── deployments/          ← Customer-specific configs
│   ├── _template/        ← Copy this for new customers
│   ├── contoso-eastus/   ← Customer deployment
│   └── contoso-weu/      ← Another region
└── .github/
    └── copilot-instructions.md  ← Auto-detected by Copilot
```

## 🚦 Deployment Workflow

```
New Customer Request
       ↓
Copy Template Folder
       ↓
Edit terraform.tfvars
       ↓
terraform init
       ↓
terraform validate  ← Check syntax
       ↓
terraform plan      ← Review changes
       ↓
Review Output       ← Verify resources & names
       ↓
terraform apply     ← Deploy
       ↓
terraform output    ← Get resource info
       ↓
Configure Access    ← Set up RBAC, etc.
```

## 🔍 Useful Commands

```bash
# Validate syntax
terraform validate

# Preview changes
terraform plan

# Apply with auto-approve (use carefully!)
terraform apply -auto-approve

# View outputs
terraform output

# List resources
terraform state list

# Show specific resource
terraform state show module.networking[0].azurerm_virtual_network.vnet

# Destroy everything (DANGER!)
terraform destroy

# Format code
terraform fmt -recursive
```

## 🐛 Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| Module not found | Check you're in deployment folder |
| Resource exists | Use `terraform import` or rename |
| Name too long | Shorten `customer_short_name` |
| Auth failed | Run `az login` |
| Wrong subscription | Run `az account set --subscription {id}` |
| State locked | Wait or break lock carefully |

## 📝 Module Enable/Disable

To add a module to existing deployment:

```bash
# 1. Edit terraform.tfvars
enable_app_service = true

# 2. Uncomment module in main.tf
# Remove the # comment markers

# 3. Configure variables
app_service_sku_name = "P1v2"

# 4. Apply
terraform plan
terraform apply
```

To remove a module:

```bash
# 1. Edit terraform.tfvars
enable_app_service = false

# 2. Apply (will destroy resources!)
terraform plan  # Review deletions!
terraform apply
```

## 🔐 Security Checklist

- ✅ Never commit `terraform.tfvars` with real values
- ✅ Use remote state storage for production
- ✅ Enable RBAC on Key Vault
- ✅ Use managed identities where possible
- ✅ Review NSG rules before deployment
- ✅ Enable diagnostic logging
- ✅ Tag all resources for cost tracking
- ✅ Use Azure Policy for compliance

## 📚 Documentation Quick Links

| Document | When to Use |
|----------|-------------|
| [README.md](README.md) | Project overview |
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Step-by-step instructions |
| [REGION_CODES.md](REGION_CODES.md) | Find region codes |
| [.github/copilot-instructions.md](.github/copilot-instructions.md) | Full template details |
| `modules/*/README.md` | Module-specific help |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | What you've built |

## 🤖 Ask GitHub Copilot

Copilot understands this template! Try asking:

- "Add a new deployment for Fabrikam in UK South"
- "Enable the Redis cache module"
- "What's the naming convention for storage accounts?"
- "How do I deploy to multiple regions?"
- "Show me how to configure custom subnets"
- "What security features are enabled?"

## 🎯 Next Actions

1. **First Deployment**: Follow [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
2. **Customize**: Add your own modules or configurations
3. **CI/CD**: Set up automated deployments
4. **Monitor**: Configure Azure Monitor and alerts
5. **Govern**: Apply Azure Policies

---

**Need help?** Ask GitHub Copilot or check the documentation!
