# Module Index - All Available Modules

Complete reference for all infrastructure modules in this template.

**Start with `CONVENTIONS.md`** before writing root code — it documents the
naming, network-access, and diagnostics conventions every module here should
follow, so you don't need to re-derive them from source per module.

## ✅ Available Modules (28 Total)

### 🏗️ Core Infrastructure (Always Required)

| Module | Purpose | Status | Files |
|--------|---------|--------|-------|
| **resource-group** | Resource Groups | ✅ Complete | All .tf + README |
| **networking** | VNet, Subnets, NSGs | ✅ Complete | All .tf + README |
| **storage-account** | Azure Storage | ✅ Complete | All .tf + README |
| **key-vault** | Azure Key Vault | ✅ Complete | All .tf + README |
| **log-analytics** | Centralized Logging | ✅ Complete | All .tf + README |
| **application-insights** | APM & Monitoring | ✅ Complete | All .tf + README |
| **diagnostic-setting** | Ship logs/metrics to Log Analytics | ✅ Complete | All .tf + README |
| **private-endpoints** | Private PaaS Connectivity | ✅ Complete | All .tf + README |
| **private-dns-zone** | Private DNS zone + VNet links | ✅ Complete | All .tf + README |

### 💻 Compute & Hosting

| Module | Purpose | Status | Files |
|--------|---------|--------|-------|
| **virtual-machine** | Azure VMs | ✅ Complete | All .tf + README |
| **app-service** | Web Apps | ✅ Complete | All .tf + README |
| **azure-functions** | Serverless Functions | ✅ Complete | All .tf + README |
| **static-web-app** | Modern Web Apps | 📝 Candidate | README only |
| **aks** | Kubernetes Service | ✅ Implemented | All .tf + README |
| **container-instances** | Containerized Apps | ✅ Implemented | All .tf + README |
| **container-registry** | Docker/OCI Registry | ✅ Complete | All .tf + README |
| **api-management** | API Gateway & Policies | ✅ Implemented | All .tf + README |

### 🌐 Networking & Load Balancing

| Module | Purpose | Status | Files |
|--------|---------|--------|-------|
| **load-balancer** | L4 Load Balancing | 📝 Candidate | README only |
| **application-gateway** | L7 + WAF | 📝 Candidate | README only |
| **vpn-gateway** | VPN Connectivity | 📝 Candidate | README only |
| **azure-firewall** | Network Security | 📝 Candidate | README only |
| **front-door** | Global CDN/LB | 📝 Candidate | README only |
| **public-ip** | Public IP Addresses | 📝 Candidate | README only |
| **azure-bastion** | Secure VM Access | 📝 Candidate | README only |

### 💾 Data & Cache

| Module | Purpose | Status | Files |
|--------|---------|--------|-------|
| **sql-database** | Azure SQL | ✅ Complete | All .tf + README |
| **cosmos-db** | NoSQL, Global Distribution | ✅ Implemented | All .tf + README |
| **redis-cache** | In-Memory Cache | ✅ Implemented | All .tf + README |

### 🔄 Integration & API

| Module | Purpose | Status | Files |
|--------|---------|--------|-------|
| **logic-app** | Workflow Automation | 📝 Candidate | README only |
| **api-management** | API Gateway & Policies | ✅ Implemented | All .tf + README |

## 📋 Module Details

### Core Infrastructure Modules

#### resource-group
**Purpose**: Resource groups, named/located by the caller (see `CONVENTIONS.md` #1)
**Resources**: Resource Group (map, 1+ per call)
**Naming**: caller-supplied — no formula baked into the module
**Status**: ✅ Production Ready
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### diagnostic-setting
**Purpose**: Ship one resource's logs/metrics to a Log Analytics workspace
**Resources**: Diagnostic Setting
**Naming**: caller-supplied
**Status**: ✅ Production Ready
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### private-endpoints
**Purpose**: Private connectivity to Azure PaaS services
**Resources**: Private Endpoint + DNS zone group
**Naming**: caller-supplied (`pep-{service}-{customer}-{env}-{region}-{instance}` is the suggested pattern — see README)
**Status**: ✅ Production Ready
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### private-dns-zone
**Purpose**: Private DNS zone + VNet links, typically owned by a hub root
**Resources**: Private DNS Zone, VNet Links
**Naming**: caller-supplied (use the exact `privatelink.*` zone name Azure expects)
**Status**: ✅ Production Ready
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### networking
**Purpose**: Foundation networking infrastructure (VNet, Subnets, NSGs) — does not create its own resource group, see `CONVENTIONS.md` #1
**Resources**: VNet, Subnets, NSGs
**Naming**: caller-supplied `name` (suggested: `vnet-{customer}-{env}-{region}-{instance}`)
**Status**: ✅ Production Ready
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### storage-account
**Purpose**: Blob and file storage, deny-by-default network firewall
**Resources**: Storage Account, Containers
**Naming**: caller-supplied `name` (suggested: `st{customer}{env}{region}{instance}`, no hyphens)
**Status**: ✅ Production Ready
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### key-vault
**Purpose**: Secrets and certificate management, deny-by-default network firewall
**Resources**: Key Vault
**Naming**: caller-supplied `name` (suggested: `kv-{customer}-{env}-{region}-{instance}`)
**Status**: ✅ Production Ready
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### log-analytics
**Purpose**: Centralized logging and monitoring  
**Resources**: Log Analytics Workspace  
**Naming**: caller-supplied `name` (suggested: `log-{customer}-{env}-{region}-{instance}`)  
**Status**: ✅ Production Ready  
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### application-insights
**Purpose**: Application Performance Monitoring (APM)  
**Resources**: Application Insights, Workspace connection  
**Naming**: caller-supplied `name` (suggested: `appi-{apptype}-{customer}-{env}-{region}-{instance}`)  
**Status**: ✅ Implemented  
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

### Compute & Hosting Modules

#### virtual-machine
**Purpose**: IaaS virtual machines  
**Resources**: Linux VM, NIC, managed OS disk  
**Naming**: caller-supplied VM and NIC names  
**Status**: ✅ Implemented  
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### app-service
**Purpose**: PaaS web application hosting  
**Resources**: Linux Web App, optional App Service Plan  
**Naming**: caller-supplied app and plan names  
**Status**: ✅ Implemented  
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### azure-functions
**Purpose**: Serverless compute  
**Resources**: Linux Function App, optional App Service Plan (host storage supplied)  
**Naming**: caller-supplied app and plan names  
**Status**: ✅ Implemented  
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### aks
**Purpose**: Managed Kubernetes cluster for container orchestration  
**Resources**: AKS Cluster, Node Pools  
**Naming**: caller-supplied `name` (suggested: `aks-{customer}-{env}-{region}-{instance}`)  
**Status**: ✅ Implemented  
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### container-registry
**Purpose**: Private Docker registry  
**Resources**: Container Registry  
**Naming**: caller-supplied `name` (suggested: `acr{customer}{env}{region}{instance}`)  
**Status**: ✅ Implemented  
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### container-instances
**Purpose**: Serverless containerized applications  
**Resources**: Container Group, Containers  
**Naming**: caller-supplied `name` (suggested: `aci-{customer}-{env}-{region}-{instance}`)  
**Status**: ✅ Implemented  
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### api-management
**Purpose**: API Gateway with policies and security  
**Resources**: APIM Instance, APIs, Products  
**Naming**: caller-supplied `name` (suggested: `apim-{customer}-{env}-{region}-{instance}`)  
**Status**: ✅ Implemented  
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

### Networking & Load Balancing Modules

#### load-balancer
**Purpose**: Layer 4 load balancing  
**Resources**: Load Balancer, Backend Pools, Health Probes  
**Naming**: `lb-{customer}-{env}-{region}-{instance}`  
**Status**: 📝 Candidate  
**Files**: README.md

#### application-gateway
**Purpose**: Layer 7 load balancing with WAF  
**Resources**: Application Gateway, Public IP  
**Naming**: `agw-{customer}-{env}-{region}-{instance}`  
**Status**: 📝 Candidate  
**Files**: README.md

#### front-door
**Purpose**: Global load balancing and CDN  
**Resources**: Front Door Profile, Endpoints  
**Naming**: `fd-{customer}-{env}-global-{instance}`  
**Status**: 📝 Candidate  
**Files**: README.md

#### public-ip
**Purpose**: Public IP addresses  
**Resources**: Public IP  
**Naming**: `pip-{purpose}-{customer}-{env}-{region}-{instance}`  
**Status**: 📝 Candidate  
**Files**: README.md

#### azure-bastion
**Purpose**: Secure RDP/SSH access  
**Resources**: Bastion Host, Public IP  
**Naming**: `bas-{customer}-{env}-{region}-{instance}`  
**Status**: 📝 Candidate  
**Files**: README.md

(`private-endpoints` and `private-dns-zone` moved to Core Infrastructure Modules above — every workload needs them, not just networking-heavy ones.)

### Data & Cache Modules

#### sql-database
**Purpose**: Relational database service — no public endpoint by default (`public_network_access_enabled = false`, see `CONVENTIONS.md` #2)
**Resources**: SQL Server, SQL Database
**Naming**: caller-supplied `name` for the server (suggested: `sql-{customer}-{env}-{region}-{instance}`)
**Status**: ✅ Production Ready
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### cosmos-db
**Purpose**: Globally distributed multi-model NoSQL database  
**Resources**: Cosmos DB Account (SQL/Core or MongoDB API)  
**Naming**: caller-supplied `name` (suggested: `cosmos-{customer}-{env}-{region}-{instance}`)  
**Status**: ✅ Implemented  
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

#### redis-cache
**Purpose**: In-memory caching  
**Resources**: Azure Cache for Redis  
**Naming**: caller-supplied `name` (suggested: `redis-{customer}-{env}-{region}-{instance}`)  
**Status**: ✅ Implemented  
**Files**: main.tf, variables.tf, outputs.tf, versions.tf, README.md

### Integration & Automation Modules

#### logic-app
**Purpose**: Workflow automation and integration  
**Resources**: Logic App (Standard/Consumption)  
**Naming**: `logic-{customer}-{env}-{region}-{instance}`  
**Status**: 📝 Candidate  
**Files**: README.md

### Web & Static Content Modules

#### static-web-app
**Purpose**: Modern static web application hosting  
**Resources**: Static Web App  
**Naming**: `stapp-{customer}-{env}-{region}-{instance}`  
**Status**: 📝 Candidate  
**Files**: README.md

### VPN & Connectivity Modules

#### vpn-gateway
**Purpose**: Site-to-site and point-to-site VPN connectivity  
**Resources**: VPN Gateway, Public IP, Local Network Gateway  
**Naming**: `vpngw-{customer}-{env}-{region}-{instance}`  
**Status**: 📝 Candidate  
**Files**: README.md

#### azure-firewall
**Purpose**: Network security and traffic filtering  
**Resources**: Azure Firewall, Firewall Policy, Public IP  
**Naming**: `afw-{customer}-{env}-{region}-{instance}`  
**Status**: 📝 Candidate  
**Files**: README.md

## 🎯 Common Module Combinations

### Basic Landing Zone
```
✓ resource-group
✓ networking
✓ storage-account
✓ key-vault
✓ log-analytics
✓ diagnostic-setting   (once per monitored resource)
```

### Add private connectivity to any stack above
```
✓ private-dns-zone     (once per Azure service used, in the hub/shared root)
✓ private-endpoints    (once per sub-resource, e.g. blob + file = 2 calls)
```
See `CONVENTIONS.md` #2 for the network-access variable pattern this pairs with.

### Web Application Stack
```
✓ networking
✓ storage-account
✓ key-vault
✓ log-analytics
✓ app-service
✓ sql-database
✓ redis-cache
✓ application-gateway
```

### VM-Based Infrastructure
```
✓ networking
✓ storage-account
✓ key-vault
✓ log-analytics
✓ virtual-machine
✓ load-balancer
✓ azure-bastion
```

### Serverless Architecture
```
✓ networking
✓ storage-account
✓ key-vault
✓ log-analytics
✓ azure-functions
✓ sql-database
✓ front-door
```

### Container Workload
```
✓ networking
✓ storage-account
✓ key-vault
✓ log-analytics
✓ container-registry
✓ load-balancer
```

## 📝 Module Implementation Status

| Status | Description | Count |
|--------|-------------|-------|
| ✅ Implemented | Complete with all required files and included in validation | 19 |
| 📝 Candidate | README documentation only; not callable Terraform | 9 |

**Total Modules**: 28

## 🚀 Next Steps for Module Development

To implement full Terraform code for README-only modules:

1. Follow `IMPLEMENTATION_ROADMAP.md` and the pattern from an implemented module
2. Create: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
3. Accept exact names from the calling root; follow `CONVENTIONS.md`
4. Include security best practices
5. Add validation to variables
6. Document outputs and add the module to the automated validation gate

## 🤖 Using Modules with GitHub Copilot

Copilot understands all these modules! Ask:
- "Enable the SQL database module"
- "Add Application Gateway to my deployment"
- "Configure Azure Functions with VNet integration"
- "What modules do I need for a web application?"

## 📚 Documentation

Each module has a detailed README with:
- Usage examples
- Variable descriptions
- Output values
- Naming conventions
- Security features
- Common patterns

See `modules/{module-name}/README.md` for details.
