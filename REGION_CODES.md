# Azure Region Codes Reference

Quick reference for Azure region codes used in this template.

## Format

Region codes follow this pattern in resource names:
```
{resource}-{customer}-{env}-{region-code}-{instance}
```

## Region Codes

### Americas

| Azure Region | Region Code | Location |
|--------------|-------------|----------|
| eastus | `eus` | East US (Virginia) |
| eastus2 | `eus2` | East US 2 (Virginia) |
| westus | `wus` | West US (California) |
| westus2 | `wus2` | West US 2 (Washington) |
| westus3 | `wus3` | West US 3 (Arizona) |
| centralus | `cus` | Central US (Iowa) |
| northcentralus | `ncus` | North Central US (Illinois) |
| southcentralus | `scus` | South Central US (Texas) |
| westcentralus | `wcus` | West Central US (Wyoming) |
| canadacentral | `cac` | Canada Central (Toronto) |
| canadaeast | `cae` | Canada East (Quebec) |
| brazilsouth | `brs` | Brazil South (São Paulo) |

### Europe

| Azure Region | Region Code | Location |
|--------------|-------------|----------|
| northeurope | `neu` | North Europe (Ireland) |
| westeurope | `weu` | West Europe (Netherlands) |
| uksouth | `uks` | UK South (London) |
| ukwest | `ukw` | UK West (Cardiff) |
| francecentral | `frc` | France Central (Paris) |
| francesouth | `frs` | France South (Marseille) |
| germanywestcentral | `gwc` | Germany West Central (Frankfurt) |
| norwayeast | `noe` | Norway East (Oslo) |
| switzerlandnorth | `szn` | Switzerland North (Zurich) |
| swedencentral | `swc` | Sweden Central (Gävle) |

### Asia Pacific

| Azure Region | Region Code | Location |
|--------------|-------------|----------|
| southeastasia | `sea` | Southeast Asia (Singapore) |
| eastasia | `eas` | East Asia (Hong Kong) |
| australiaeast | `aue` | Australia East (Sydney) |
| australiasoutheast | `aus` | Australia Southeast (Melbourne) |
| australiacentral | `auc` | Australia Central (Canberra) |
| japaneast | `jpe` | Japan East (Tokyo) |
| japanwest | `jpw` | Japan West (Osaka) |
| koreacentral | `krc` | Korea Central (Seoul) |
| koreasouth | `krs` | Korea South (Busan) |
| centralindia | `inc` | Central India (Pune) |
| southindia | `ins` | South India (Chennai) |
| westindia | `inw` | West India (Mumbai) |

### Middle East & Africa

| Azure Region | Region Code | Location |
|--------------|-------------|----------|
| uaenorth | `uan` | UAE North (Dubai) |
| uaecentral | `uac` | UAE Central (Abu Dhabi) |
| southafricanorth | `san` | South Africa North (Johannesburg) |
| southafricawest | `saw` | South Africa West (Cape Town) |

### Special Regions

| Azure Region | Region Code | Location/Purpose |
|--------------|-------------|------------------|
| global | `global` | Global services (Front Door, Traffic Manager) |

## Usage Examples

### Example 1: East US Deployment
```hcl
location      = "eastus"
location_code = "eus"
```

Resources created:
- VNet: `vnet-contoso-prod-eus-001`
- Storage: `stcontosoprodeus001`
- Key Vault: `kv-contoso-prod-eus-001`

### Example 2: West Europe Deployment
```hcl
location      = "westeurope"
location_code = "weu"
```

Resources created:
- VNet: `vnet-contoso-prod-weu-001`
- Storage: `stcontosoprodweu001`
- Key Vault: `kv-contoso-prod-weu-001`

### Example 3: Southeast Asia Deployment
```hcl
location      = "southeastasia"
location_code = "sea"
```

Resources created:
- VNet: `vnet-contoso-prod-sea-001`
- Storage: `stcontosoprodsea001`
- Key Vault: `kv-contoso-prod-sea-001`

## Choosing a Region

Consider these factors when selecting regions:

1. **Data Residency**: Legal/compliance requirements for data location
2. **Latency**: Proximity to users/customers
3. **Service Availability**: Not all services available in all regions
4. **Cost**: Pricing varies by region
5. **Disaster Recovery**: Choose paired regions for redundancy

## Azure Region Pairs

Azure regions are paired for disaster recovery:

| Primary Region | Paired Region | Codes |
|----------------|---------------|-------|
| East US | West US | `eus` ↔ `wus` |
| East US 2 | Central US | `eus2` ↔ `cus` |
| West Europe | North Europe | `weu` ↔ `neu` |
| Southeast Asia | East Asia | `sea` ↔ `eas` |
| UK South | UK West | `uks` ↔ `ukw` |
| Australia East | Australia Southeast | `aue` ↔ `aus` |
| Japan East | Japan West | `jpe` ↔ `jpw` |

## Multi-Region Deployment Example

Deploying to paired regions for high availability:

```bash
# Primary region: East US
cd deployments
mkdir contoso-eastus
cd contoso-eastus
# Configure with location = "eastus", location_code = "eus"

# Secondary region: West US
cd ..
mkdir contoso-westus
cd contoso-westus
# Configure with location = "westus", location_code = "wus"

# Optional: Front Door for global load balancing
# Set enable_front_door = true in one deployment
```

## Custom Region Codes

If you prefer different codes, update `location_code` in `terraform.tfvars`:

```hcl
# Standard
location      = "eastus"
location_code = "eus"

# Custom (if you prefer 2-letter codes)
location      = "eastus"
location_code = "eu"

# Custom (if you prefer longer codes)
location      = "eastus"
location_code = "eastus"
```

**Note**: Keep codes short (2-4 characters) to avoid hitting Azure resource name length limits.

## Reference Links

- [Azure Geographies](https://azure.microsoft.com/global-infrastructure/geographies/)
- [Azure Regions](https://azure.microsoft.com/global-infrastructure/regions/)
- [Products by Region](https://azure.microsoft.com/global-infrastructure/services/)
