# Multiple Named Instances Guide

## Overview

The Terraform template now supports **multiple named instances** of resources using `for_each` with named keys. This allows you to create multiple storage accounts, Key Vaults, and SQL databases for different applications or purposes within a single deployment.

## Why Named Instances?

In real-world scenarios, resources serve specific purposes tied to applications:
- **Storage Accounts**: One for data, one for logs, one for backups, one per application
- **Key Vaults**: Separate vaults for secrets, certificates, or per application
- **SQL Databases**: One per microservice or application component

Instead of deploying 10 identical resources, you deploy 10 **named, purpose-driven** resources.

## Resource Naming Pattern

Each resource uses a **name suffix** to identify its purpose:

```
Storage Account:  st{customer}{env}{region}{instance}{suffix}
Example:          stcontosoprodeus001data
                  stcontosoprodeus001logs
                  stcontosoprodeus001appx

Key Vault:        kv-{customer}-{env}-{region}-{instance}-{suffix}
Example:          kv-contoso-prod-eus-001-secrets
                  kv-contoso-prod-eus-001-certs
                  kv-contoso-prod-eus-001-appx

SQL Server:       sql-{customer}-{env}-{region}-{instance}-{suffix}
Example:          sql-contoso-prod-eus-001-orders
                  sql-contoso-prod-eus-001-inventory
                  sql-contoso-prod-eus-001-appx
```

## Configuration Format

### Storage Accounts

```hcl
storage_accounts = {
  data = {
    tier              = "Standard"
    replication_type  = "LRS"
    blob_containers   = ["uploads", "processed", "archive"]
  }
  logs = {
    tier              = "Standard"
    replication_type  = "LRS"
    blob_containers   = ["app-logs", "audit-logs"]
  }
  backups = {
    tier              = "Standard"
    replication_type  = "GRS"  # Geo-redundant
    blob_containers   = ["sql-backups", "vm-snapshots"]
  }
}
```

**Resulting Resources:**
- `stcontosoprodeus001data` with 3 containers
- `stcontosoprodeus001logs` with 2 containers
- `stcontosoprodeus001backups` with 2 containers (geo-replicated)

### Key Vaults

```hcl
key_vaults = {
  secrets = {
    sku_name    = "standard"
    enable_rbac = true
  }
  certs = {
    sku_name    = "premium"  # Premium for HSM-backed certs
    enable_rbac = true
  }
  appx = {
    sku_name    = "standard"
    enable_rbac = true
  }
}
```

**Resulting Resources:**
- `kv-contoso-prod-eus-001-secrets` (Standard SKU)
- `kv-contoso-prod-eus-001-certs` (Premium SKU)
- `kv-contoso-prod-eus-001-appx` (Standard SKU)

### SQL Databases

```hcl
sql_databases = {
  orders = {
    admin_username = "sqladmin"
    admin_password = "ChangeMe123!SecurePassword"
    database_name  = "OrdersDB"
    sku_name       = "S1"
    max_size_gb    = 250
    zone_redundant = false
  }
  inventory = {
    admin_username = "sqladmin"
    admin_password = "ChangeMe123!SecurePassword"
    database_name  = "InventoryDB"
    sku_name       = "S2"
    max_size_gb    = 500
    zone_redundant = true
  }
}
```

**Resulting Resources:**
- `sql-contoso-prod-eus-001-orders` with `OrdersDB` (S1, 250GB)
- `sql-contoso-prod-eus-001-inventory` with `InventoryDB` (S2, 500GB, zone-redundant)

## Complete Example: E-Commerce Platform

```hcl
# deployments/contoso-eastus/terraform.tfvars

customer_short_name = "contoso"
environment         = "prod"
location            = "eastus"
location_code       = "eus"
subscription_id     = "12345678-1234-1234-1234-123456789abc"

# Networking (shared)
enable_networking = true
vnet_address_space = ["10.0.0.0/16"]

# 5 Storage Accounts for different purposes
storage_accounts = {
  web = {
    tier              = "Standard"
    replication_type  = "ZRS"
    blob_containers   = ["static-content", "user-uploads"]
  }
  orders = {
    tier              = "Standard"
    replication_type  = "LRS"
    blob_containers   = ["order-documents", "invoices"]
  }
  inventory = {
    tier              = "Standard"
    replication_type  = "LRS"
    blob_containers   = ["product-images", "sku-data"]
  }
  logs = {
    tier              = "Standard"
    replication_type  = "LRS"
    blob_containers   = ["app-logs", "audit-logs", "access-logs"]
  }
  backups = {
    tier              = "Standard"
    replication_type  = "GRS"
    blob_containers   = ["database-backups", "vm-backups"]
  }
}

# 3 Key Vaults for separation of concerns
key_vaults = {
  web = {
    sku_name    = "standard"
    enable_rbac = true
  }
  database = {
    sku_name    = "premium"  # HSM-backed for connection strings
    enable_rbac = true
  }
  certs = {
    sku_name    = "premium"  # HSM-backed for SSL certificates
    enable_rbac = true
  }
}

# 4 SQL Databases for microservices
sql_databases = {
  orders = {
    admin_username = "sqladmin"
    admin_password = "ChangeMe123!SecurePassword"  # Reference from Key Vault
    database_name  = "OrdersDB"
    sku_name       = "S2"
    max_size_gb    = 500
    zone_redundant = true
  }
  inventory = {
    admin_username = "sqladmin"
    admin_password = "ChangeMe123!SecurePassword"
    database_name  = "InventoryDB"
    sku_name       = "S1"
    max_size_gb    = 250
    zone_redundant = false
  }
  customers = {
    admin_username = "sqladmin"
    admin_password = "ChangeMe123!SecurePassword"
    database_name  = "CustomersDB"
    sku_name       = "S3"
    max_size_gb    = 1000
    zone_redundant = true
  }
  analytics = {
    admin_username = "sqladmin"
    admin_password = "ChangeMe123!SecurePassword"
    database_name  = "AnalyticsDB"
    sku_name       = "P1"
    max_size_gb    = 2000
    zone_redundant = true
  }
}

tags = {
  Environment = "Production"
  ManagedBy   = "Terraform"
  Customer    = "Contoso"
  CostCenter  = "IT-Ecommerce"
}
```

## Terraform Outputs

After deployment, you'll get structured outputs:

```hcl
storage_accounts = {
  "web" = {
    name          = "stcontosoprodeus001web"
    id            = "/subscriptions/.../stcontosoprodeus001web"
    blob_endpoint = "https://stcontosoprodeus001web.blob.core.windows.net/"
    purpose       = "web"
  }
  "orders" = {
    name          = "stcontosoprodeus001orders"
    id            = "/subscriptions/.../stcontosoprodeus001orders"
    blob_endpoint = "https://stcontosoprodeus001orders.blob.core.windows.net/"
    purpose       = "orders"
  }
  # ... etc
}

key_vaults = {
  "web" = {
    name    = "kv-contoso-prod-eus-001-web"
    id      = "/subscriptions/.../kv-contoso-prod-eus-001-web"
    uri     = "https://kv-contoso-prod-eus-001-web.vault.azure.net/"
    purpose = "web"
  }
  # ... etc
}

sql_databases = {
  "orders" = {
    server_name   = "sql-contoso-prod-eus-001-orders"
    server_fqdn   = "sql-contoso-prod-eus-001-orders.database.windows.net"
    database_name = "OrdersDB"
    purpose       = "orders"
  }
  # ... etc
}
```

## Accessing Specific Resources in Code

Reference specific resources using their keys:

```hcl
# Reference the "data" storage account
data "azurerm_storage_account" "data" {
  name                = "stcontosoprodeus001data"
  resource_group_name = "rg-contoso-prod-eus-001"
}

# Reference the "secrets" Key Vault
data "azurerm_key_vault" "secrets" {
  name                = "kv-contoso-prod-eus-001-secrets"
  resource_group_name = "rg-contoso-prod-eus-001"
}

# Get connection string from outputs
output "orders_db_connection" {
  value     = module.sql_database["orders"].connection_string
  sensitive = true
}
```

## Naming Constraints

### Storage Accounts
- **Suffix**: 1-10 characters
- **Characters**: Lowercase alphanumeric only (no hyphens)
- **Total Length**: 3-24 characters
- **Examples**: `data`, `logs`, `app1`, `webstatic`

### Key Vaults
- **Suffix**: 1-12 characters
- **Characters**: Lowercase alphanumeric and hyphens
- **Total Length**: 3-24 characters
- **Examples**: `secrets`, `certs`, `app-keys`, `web-config`

### SQL Servers
- **Suffix**: 1-15 characters
- **Characters**: Lowercase alphanumeric and hyphens
- **Total Length**: Up to 63 characters
- **Examples**: `orders`, `inventory`, `app-db`, `analytics`

## Migration from Boolean Flags

### Old Way (Single Instance)
```hcl
enable_storage_account = true
storage_account_tier   = "Standard"
storage_account_replication_type = "LRS"
```

This creates: `stcontosoprodeus001`

### New Way (Multiple Named Instances)
```hcl
storage_accounts = {
  default = {
    tier             = "Standard"
    replication_type = "LRS"
    blob_containers  = []
  }
}
```

This creates: `stcontosoprodeus001default`

To maintain backward compatibility with names, omit the suffix in module code (already supported in modules).

## Best Practices

### 1. Use Descriptive Suffixes
✅ Good: `orders`, `inventory`, `logs`, `backups`  
❌ Bad: `sa1`, `sa2`, `kv1`, `db1`

### 2. Group by Application
```hcl
storage_accounts = {
  webapp   = { ... }
  webcdn   = { ... }
  weblogs  = { ... }
}

key_vaults = {
  webapp   = { ... }
  webapi   = { ... }
}
```

### 3. Separate by Tier
```hcl
key_vaults = {
  secrets = {
    sku_name = "standard"  # App secrets
  }
  certs = {
    sku_name = "premium"   # HSM-backed certificates
  }
}
```

### 4. Use Consistent Naming Across Environments
```hcl
# dev/terraform.tfvars
storage_accounts = {
  app1 = { ... }
  app2 = { ... }
}

# prod/terraform.tfvars
storage_accounts = {
  app1 = { ... }  # Same suffix
  app2 = { ... }  # Same suffix
}
```

## Scaling to 10+ Resources

Creating 10 storage accounts:
```hcl
storage_accounts = {
  web        = { tier = "Standard", replication_type = "ZRS", blob_containers = [] }
  api        = { tier = "Standard", replication_type = "LRS", blob_containers = [] }
  orders     = { tier = "Standard", replication_type = "LRS", blob_containers = [] }
  inventory  = { tier = "Standard", replication_type = "LRS", blob_containers = [] }
  customers  = { tier = "Standard", replication_type = "LRS", blob_containers = [] }
  products   = { tier = "Standard", replication_type = "LRS", blob_containers = [] }
  analytics  = { tier = "Standard", replication_type = "LRS", blob_containers = [] }
  logs       = { tier = "Standard", replication_type = "LRS", blob_containers = [] }
  backups    = { tier = "Standard", replication_type = "GRS", blob_containers = [] }
  archive    = { tier = "Standard", replication_type = "GRS", blob_containers = [] }
}
```

Results in 10 storage accounts:
- `stcontosoprodeus001web`
- `stcontosoprodeus001api`
- ... (8 more)

## Terraform Commands

```bash
# Initialize
terraform init

# Plan (shows all resources)
terraform plan

# Apply (creates all resources)
terraform apply

# Show outputs
terraform output storage_accounts
terraform output key_vaults
terraform output sql_databases

# Target specific resource
terraform apply -target=module.storage_account[\"data\"]
terraform destroy -target=module.key_vault[\"certs\"]
```

## Common Questions

**Q: Can I have zero storage accounts?**  
A: Yes! Set `storage_accounts = {}` and no storage accounts will be created.

**Q: Can I mix named instances with the old boolean flags?**  
A: No, the template has been updated to use `for_each` exclusively. The boolean flags for storage/KV have been removed.

**Q: How do I add more resources later?**  
A: Just add a new entry to the map:
```hcl
storage_accounts = {
  data = { ... }  # Existing
  logs = { ... }  # Existing
  new  = { ... }  # New - just add this
}
```

**Q: What if I need different configurations per resource?**  
A: That's the power of `for_each`! Each entry can have completely different settings:
```hcl
storage_accounts = {
  standard = {
    tier              = "Standard"
    replication_type  = "LRS"
    blob_containers   = []
  }
  premium = {
    tier              = "Premium"  # Different tier
    replication_type  = "ZRS"      # Different replication
    blob_containers   = ["high-iops-data"]
  }
}
```

---

**Ready to use!** Copy the `_template` folder for your new customer and configure multiple named instances in `terraform.tfvars`.
