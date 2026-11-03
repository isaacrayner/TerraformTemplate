# Azure Terraform Template

A versioned Terraform module catalog and customer deployment starter for Azure.
Fourteen modules are currently implemented and validated; the remaining catalog
entries are staged design candidates, not callable Terraform modules.

## 🚀 Quick Start

1. **Create a new customer deployment**:
   ```bash
   cd deployments
   cp -r _template contoso-eastus
   cd contoso-eastus
   ```

2. **Configure for your customer**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with customer-specific values
   ```

3. **Deploy**:
   ```bash
   terraform init
   terraform validate
   terraform plan
   terraform apply
   ```

## 📁 Structure

```
TerraformTemplate/
├── modules/                    # Reusable infrastructure modules
│   ├── networking/            # VNet, Subnets, NSGs
│   ├── storage-account/       # Azure Storage Account
│   ├── key-vault/            # Azure Key Vault
│   ├── virtual-machine/      # Azure VMs
│   ├── app-service/          # Azure App Service
│   ├── front-door/           # Azure Front Door
│   └── redis-cache/          # Azure Redis Cache
├── deployments/               # Customer/region-specific deployments
│   └── _template/            # Template for new deployments
├── .github/
│   └── copilot-instructions.md  # LLM instructions (auto-detected by GitHub Copilot)
├── DEPLOYMENT_GUIDE.md        # Complete deployment guide
├── REGION_CODES.md           # Azure region codes reference
└── README.md                 # This file
```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Complete step-by-step deployment guide |
| [CUSTOMER_DEPLOYMENT_STRATEGY.md](CUSTOMER_DEPLOYMENT_STRATEGY.md) | **🔥 Multi-customer Azure DevOps repository strategy** |
| [NEW_CUSTOMER_CHECKLIST.md](NEW_CUSTOMER_CHECKLIST.md) | **🔥 Step-by-step checklist for onboarding new customers** |
| [REPO_STRUCTURE_GUIDE.md](REPO_STRUCTURE_GUIDE.md) | Repository structure and isolation strategy |
| [.azure-pipelines/terraform-deploy.yml](.azure-pipelines/terraform-deploy.yml) | Complete CI/CD pipeline example |
| [.github/copilot-instructions.md](.github/copilot-instructions.md) | Full template documentation (auto-detected by GitHub Copilot) |
| [REGION_CODES.md](REGION_CODES.md) | Azure region codes reference |
| [MODULES_INDEX.md](MODULES_INDEX.md) | Truthful implementation status for all 28 catalog entries |
| [IMPLEMENTATION_ROADMAP.md](IMPLEMENTATION_ROADMAP.md) | Staged path from foundation to full catalog |
| [MODULE_RELEASES.md](MODULE_RELEASES.md) | Versioning and cross-customer consumption policy |
| `modules/*/README.md` | Individual module documentation |

## 🏗️ Architecture

### Core Modules (Always Required)
- **networking** - Virtual Network, Subnets, NSGs
- **storage-account** - Azure Storage Account with security best practices
- **key-vault** - Azure Key Vault with RBAC
- **log-analytics** - Log Analytics Workspace for centralized logging
- **application-insights** - Application Insights for APM and monitoring

### Compute & Hosting Modules
- **virtual-machine** - Azure Virtual Machines
- **app-service** - Azure App Service with App Service Plan
- **azure-functions** - Azure Functions (Consumption/Premium/Dedicated)
- **static-web-app** - Azure Static Web Apps for modern web hosting
- **aks** - Azure Kubernetes Service for container orchestration
- **container-instances** - Azure Container Instances for containerized apps
- **container-registry** - Azure Container Registry (ACR)

### Networking & Load Balancing Modules
- **load-balancer** - Azure Load Balancer (Internal/Public)
- **application-gateway** - Azure Application Gateway with WAF
- **vpn-gateway** - Azure VPN Gateway for site-to-site/point-to-site connectivity
- **azure-firewall** - Azure Firewall for network security and traffic filtering
- **front-door** - Azure Front Door for global load balancing
- **public-ip** - Public IP addresses
- **azure-bastion** - Azure Bastion for secure VM access
- **private-endpoints** - Private Endpoints for secure PaaS connectivity

### Data & Cache Modules
- **sql-database** - Azure SQL Database with SQL Server
- **cosmos-db** - Azure Cosmos DB for globally distributed NoSQL
- **redis-cache** - Azure Cache for Redis

### Integration & API Modules
- **logic-app** - Azure Logic Apps for workflow automation
- **api-management** - Azure API Management for API gateway and policies

## 🎯 Key Features

✅ **Modular Design** - Use only what you need via boolean flags  
✅ **Multi-Customer** - Isolated deployments per customer  
✅ **Multi-Region** - Deploy to multiple regions easily  
✅ **Azure Best Practices** - Security, naming, and compliance built-in  
✅ **Consistent Naming** - Standardized naming convention across all resources  
✅ **GitHub Copilot Optimized** - Comprehensive LLM instructions for AI assistance  
✅ **Release-oriented** - Immutable Git tags for customer consumption  
✅ **Fully Documented** - READMEs for every module and deployment pattern  

## 📋 Naming Convention

All resources follow Azure best practices:

| Resource Type | Pattern | Example |
|---------------|---------|---------|
| Virtual Network | `vnet-{customer}-{env}-{region}-{instance}` | `vnet-contoso-prod-eus-001` |
| Storage Account | `st{customer}{env}{region}{instance}` | `stcontosoprodeus001` |
| Key Vault | `kv-{customer}-{env}-{region}-{instance}` | `kv-contoso-prod-eus-001` |
| VM | `vm-{customer}-{env}-{region}-{instance}` | `vm-contoso-prod-eus-001` |
| App Service | `app-{customer}-{env}-{region}-{instance}` | `app-contoso-prod-eus-001` |
| Front Door | `fd-{customer}-{env}-global-{instance}` | `fd-contoso-prod-global-001` |
| Redis Cache | `redis-{customer}-{env}-{region}-{instance}` | `redis-contoso-prod-eus-001` |

## 🔧 Usage Examples

The local `../../modules/...` sources below are for developing the deployment
template inside this repository. Customer repositories should use versioned Git
sources as documented in [MODULE_RELEASES.md](MODULE_RELEASES.md).

### Example 1: Baseline deployment

Maps control repeatable resources; an empty map creates none. These are real
inputs in the current deployment starter:

```hcl
enable_networking   = true
enable_log_analytics = true

storage_accounts = {
  data = {
    tier             = "Standard"
    replication_type = "LRS"
    blob_containers  = ["data"]
  }
}

key_vaults   = {}
sql_databases = {}
```

### Example 2: Separate regional state

Create independent regional roots. Global edge services remain Stage 4
candidates and should be added only after their modules are implemented.

```bash
# Create East US deployment
cd deployments
cp -r _template contoso-eastus
# Configure for East US

# Create West Europe deployment
cp -r _template contoso-westeurope
# Configure for West Europe
```

## 🌍 Multi-Region Deployment

The template supports two approaches:

### Option 1: Separate Folders (Recommended)
```
deployments/
├── contoso-eastus/
└── contoso-westeurope/
```

Each region has independent state and configuration.

### Option 2: Terraform Workspaces
```bash
terraform workspace new contoso-eastus
terraform workspace new contoso-westeurope
```

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed instructions.

## 🤖 GitHub Copilot Integration

This template includes comprehensive instructions in `.github/copilot-instructions.md` that GitHub Copilot automatically detects. When working in this repository, Copilot understands:

- Template structure and purpose
- Naming conventions
- How to add new customers
- How to configure modules
- Best practices and patterns

Simply ask Copilot questions like:
- "Add a new customer deployment for Fabrikam in West Europe"
- "Enable the App Service module"
- "What's the naming convention for storage accounts?"

## 🔐 Security Best Practices

Built-in security features:
- ✅ HTTPS-only for storage and app services
- ✅ TLS 1.2 minimum
- ✅ Key Vault RBAC authorization
- ✅ Network security groups on all subnets
- ✅ No public blob access
- ✅ Soft delete and purge protection
- ✅ Managed identity support

## 📦 Prerequisites

- **Terraform** >= 1.5.0
- **Azure CLI** (authenticated)
- **Azure subscription** with appropriate permissions

## 🚦 Getting Started

1. **Read the documentation**:
   - [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Step-by-step instructions
   - [.github/copilot-instructions.md](.github/copilot-instructions.md) - Full template details

2. **Copy the template**:
   ```bash
   cd deployments
   cp -r _template your-customer-region
   ```

3. **Configure and deploy**:
   ```bash
   cd your-customer-region
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars
   terraform init
   terraform plan
   terraform apply
   ```

## 🤝 Contributing

When adding new modules:
1. Create module folder in `modules/`
2. Include: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`
3. Follow naming convention
4. Add boolean flag to deployment template
5. Document in module README

## 📝 License

This template is provided as-is for use in your Azure deployments.

## 🆘 Support

- **Documentation**: See files in this repository
- **GitHub Copilot**: Ask questions directly in VS Code
- **Azure Docs**: [Microsoft Learn](https://learn.microsoft.com/azure/)

---

**Ready to deploy?** Start with the [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)!
