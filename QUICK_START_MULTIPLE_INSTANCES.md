# Quick Reference: Multiple Named Instances

## Basic Syntax

```hcl
# terraform.tfvars

storage_accounts = {
  KEY = {
    tier              = "Standard" | "Premium"
    replication_type  = "LRS" | "GRS" | "ZRS" | "GZRS"
    blob_containers   = ["container1", "container2"]
  }
}

key_vaults = {
  KEY = {
    sku_name    = "standard" | "premium"
    enable_rbac = true | false
  }
}

sql_databases = {
  KEY = {
    admin_username = "username"
    admin_password = "password"
    database_name  = "DatabaseName"
    sku_name       = "Basic" | "S0" | "S1" | "P1" | ...
    max_size_gb    = 50 | 250 | 500 | 1000 | ...
    zone_redundant = true | false (optional)
  }
}
```

## Naming Results

| Key | Storage Account | Key Vault | SQL Server |
|-----|----------------|-----------|------------|
| `data` | `st{customer}{env}{region}001data` | `kv-{customer}-{env}-{region}-001-data` | `sql-{customer}-{env}-{region}-001-data` |
| `logs` | `st{customer}{env}{region}001logs` | `kv-{customer}-{env}-{region}-001-logs` | `sql-{customer}-{env}-{region}-001-logs` |
| `appX` | `st{customer}{env}{region}001appx` | `kv-{customer}-{env}-{region}-001-appx` | `sql-{customer}-{env}-{region}-001-appx` |

Example: `customer_short_name = "contoso"`, `environment = "prod"`, `location_code = "eus"`
- Storage: `stcontosoprodeus001data`
- Key Vault: `kv-contoso-prod-eus-001-secrets`
- SQL: `sql-contoso-prod-eus-001-orders`

## Common Patterns

### Pattern 1: Basic Landing Zone
```hcl
storage_accounts = {
  main = {
    tier = "Standard"
    replication_type = "LRS"
    blob_containers = []
  }
}

key_vaults = {
  main = {
    sku_name = "standard"
    enable_rbac = true
  }
}
```

### Pattern 2: Application Separation
```hcl
storage_accounts = {
  app1 = { tier = "Standard", replication_type = "LRS", blob_containers = [] }
  app2 = { tier = "Standard", replication_type = "LRS", blob_containers = [] }
  app3 = { tier = "Standard", replication_type = "LRS", blob_containers = [] }
}

key_vaults = {
  app1 = { sku_name = "standard", enable_rbac = true }
  app2 = { sku_name = "standard", enable_rbac = true }
  app3 = { sku_name = "standard", enable_rbac = true }
}

sql_databases = {
  app1 = {
    admin_username = "sqladmin"
    admin_password = "Password123!"
    database_name = "App1DB"
    sku_name = "S1"
    max_size_gb = 250
  }
  app2 = {
    admin_username = "sqladmin"
    admin_password = "Password123!"
    database_name = "App2DB"
    sku_name = "S1"
    max_size_gb = 250
  }
}
```

### Pattern 3: Functional Separation
```hcl
storage_accounts = {
  data    = { tier = "Standard", replication_type = "ZRS", blob_containers = ["processed"] }
  logs    = { tier = "Standard", replication_type = "LRS", blob_containers = ["app-logs"] }
  backups = { tier = "Standard", replication_type = "GRS", blob_containers = ["backups"] }
}

key_vaults = {
  secrets = { sku_name = "standard", enable_rbac = true }
  certs   = { sku_name = "premium", enable_rbac = true }
}
```

### Pattern 4: Microservices
```hcl
sql_databases = {
  orders = {
    admin_username = "sqladmin"
    admin_password = "Password123!"
    database_name = "OrdersDB"
    sku_name = "S2"
    max_size_gb = 500
    zone_redundant = true
  }
  inventory = {
    admin_username = "sqladmin"
    admin_password = "Password123!"
    database_name = "InventoryDB"
    sku_name = "S1"
    max_size_gb = 250
  }
  customers = {
    admin_username = "sqladmin"
    admin_password = "Password123!"
    database_name = "CustomersDB"
    sku_name = "S2"
    max_size_gb = 500
    zone_redundant = true
  }
}
```

## Terraform Commands

```bash
# Standard workflow
terraform init
terraform plan
terraform apply

# Target specific instance
terraform apply -target=module.storage_account[\"data\"]
terraform destroy -target=module.key_vault[\"certs\"]

# View outputs
terraform output storage_accounts
terraform output key_vaults
terraform output sql_databases

# View specific instance
terraform output -json storage_accounts | jq '.data'
```

## Output Structure

```hcl
# Storage Accounts
{
  "KEY" = {
    name          = "storage-account-name"
    id            = "/subscriptions/.../storage-account-name"
    blob_endpoint = "https://storage-account-name.blob.core.windows.net/"
    purpose       = "KEY"
  }
}

# Key Vaults
{
  "KEY" = {
    name    = "key-vault-name"
    id      = "/subscriptions/.../key-vault-name"
    uri     = "https://key-vault-name.vault.azure.net/"
    purpose = "KEY"
  }
}

# SQL Databases
{
  "KEY" = {
    server_name   = "sql-server-name"
    server_fqdn   = "sql-server-name.database.windows.net"
    database_name = "DatabaseName"
    database_id   = "/subscriptions/.../databases/DatabaseName"
    purpose       = "KEY"
  }
}
```

## Naming Constraints

| Resource | Key Length | Characters | Total Name Length |
|----------|-----------|------------|------------------|
| Storage Account | 1-10 chars | Lowercase alphanumeric (no hyphens) | 3-24 chars |
| Key Vault | 1-12 chars | Lowercase alphanumeric + hyphens | 3-24 chars |
| SQL Server | 1-15 chars | Lowercase alphanumeric + hyphens | Up to 63 chars |

## Quick Troubleshooting

**Error: Name too long**
- Storage: Use shorter suffix (max 10 chars)
- Key Vault: Use shorter suffix (max 12 chars)

**Error: Invalid characters**
- Storage: No hyphens allowed (use `appx` not `app-x`)
- Key Vault/SQL: Hyphens OK (use `app-x`)

**Error: Already exists**
- Check if resource was created outside Terraform
- Verify customer_short_name, environment, location_code match

**Nothing created**
- Check if map is empty: `storage_accounts = {}`
- Verify syntax (commas, braces, quotes)

## Best Practices

✅ **DO**: Use descriptive keys (`orders`, `inventory`, `web`)  
❌ **DON'T**: Use generic keys (`sa1`, `sa2`, `db1`)

✅ **DO**: Keep keys consistent across environments  
❌ **DON'T**: Use `app1` in dev and `application1` in prod

✅ **DO**: Use GRS replication for critical backups  
❌ **DON'T**: Use GRS for everything (costs 2x)

✅ **DO**: Separate secrets by application/purpose  
❌ **DON'T**: Put all secrets in one Key Vault

✅ **DO**: Use Premium Key Vault for certificates/HSM  
❌ **DON'T**: Use Premium for simple app secrets

## Empty Maps

To create zero instances:
```hcl
storage_accounts = {}
key_vaults = {}
sql_databases = {}
```

This is valid and creates no resources. Use this for environments that don't need these resources.

---

**For detailed examples, see**: `MULTIPLE_INSTANCES_GUIDE.md`  
**For what changed, see**: `WHATS_NEW.md`
