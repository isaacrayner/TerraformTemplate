# What's New: Multiple Named Instances Pattern

## 🎉 Major Update: `for_each` with Named Keys

The template has been upgraded to support **multiple named instances** of Storage Accounts, Key Vaults, and SQL Databases using Terraform's `for_each` pattern.

## Before vs. After

### ❌ Old Way (Boolean Flags)
```hcl
enable_storage_account = true
enable_key_vault = true

# Result: 1 storage account, 1 Key Vault
# - stcontosoprodeus001
# - kv-contoso-prod-eus-001
```

### ✅ New Way (Named Instances)
```hcl
storage_accounts = {
  data    = { tier = "Standard", replication_type = "LRS", blob_containers = [] }
  logs    = { tier = "Standard", replication_type = "LRS", blob_containers = [] }
  backups = { tier = "Standard", replication_type = "GRS", blob_containers = [] }
}

key_vaults = {
  secrets = { sku_name = "standard", enable_rbac = true }
  certs   = { sku_name = "premium", enable_rbac = true }
}

# Result: 3 storage accounts, 2 Key Vaults
# - stcontosoprodeus001data
# - stcontosoprodeus001logs
# - stcontosoprodeus001backups
# - kv-contoso-prod-eus-001-secrets
# - kv-contoso-prod-eus-001-certs
```

## Why This Matters

In real-world deployments, you need:
- **Multiple storage accounts** for different apps/purposes (not just one generic account)
- **Multiple Key Vaults** to separate secrets, certificates, and app configs
- **Multiple SQL databases** for microservices, not sharing one server

The suffix identifies the **purpose or application** (e.g., `orders`, `inventory`, `web`, `api`).

## What Changed

### 1. Module Updates
All three core modules now support `name_suffix`:
- `modules/storage-account` - Added `name_suffix` variable
- `modules/key-vault` - Added `name_suffix` variable
- `modules/sql-database` - Added `name_suffix` variable

### 2. Deployment Template Updates
- **variables.tf** - Replaced boolean flags with `map(object())` types
- **main.tf** - Changed from `count` to `for_each` for module instantiation
- **outputs.tf** - Returns maps of all resources instead of single values
- **terraform.tfvars.example** - Shows practical multi-instance examples

### 3. New Documentation
- `MULTIPLE_INSTANCES_GUIDE.md` - Complete guide with examples
- `WHATS_NEW.md` - This file!

## Quick Start Example

**deployments/your-customer/terraform.tfvars**

```hcl
customer_short_name = "acme"
environment         = "prod"
location            = "eastus"
location_code       = "eus"
subscription_id     = "your-subscription-id"

# Create 3 storage accounts
storage_accounts = {
  app1 = {
    tier              = "Standard"
    replication_type  = "LRS"
    blob_containers   = ["data", "logs"]
  }
  app2 = {
    tier              = "Standard"
    replication_type  = "LRS"
    blob_containers   = ["uploads"]
  }
  shared = {
    tier              = "Standard"
    replication_type  = "GRS"
    blob_containers   = ["backups"]
  }
}

# Create 2 Key Vaults
key_vaults = {
  app1 = {
    sku_name    = "standard"
    enable_rbac = true
  }
  app2 = {
    sku_name    = "standard"
    enable_rbac = true
  }
}

# Create 2 SQL Databases
sql_databases = {
  app1 = {
    admin_username = "sqladmin"
    admin_password = "YourSecurePassword123!"
    database_name  = "App1DB"
    sku_name       = "S1"
    max_size_gb    = 250
  }
  app2 = {
    admin_username = "sqladmin"
    admin_password = "YourSecurePassword123!"
    database_name  = "App2DB"
    sku_name       = "S2"
    max_size_gb    = 500
  }
}
```

**Run Terraform:**
```bash
terraform init
terraform plan   # Shows 3 SAs, 2 KVs, 2 SQL servers
terraform apply
```

**Result:** 7 total resources created with descriptive names!

## Resource Naming Examples

| Suffix | Storage Account | Key Vault | SQL Server |
|--------|----------------|-----------|------------|
| `data` | `stacmeprodeus001data` | `kv-acme-prod-eus-001-data` | `sql-acme-prod-eus-001-data` |
| `logs` | `stacmeprodeus001logs` | `kv-acme-prod-eus-001-logs` | `sql-acme-prod-eus-001-logs` |
| `orders` | `stacmeprodeus001orders` | `kv-acme-prod-eus-001-orders` | `sql-acme-prod-eus-001-orders` |
| `web` | `stacmeprodeus001web` | `kv-acme-prod-eus-001-web` | `sql-acme-prod-eus-001-web` |

## Outputs Structure

Outputs are now **maps** indexed by suffix:

```bash
$ terraform output storage_accounts

{
  "data" = {
    name          = "stacmeprodeus001data"
    id            = "/subscriptions/.../stacmeprodeus001data"
    blob_endpoint = "https://stacmeprodeus001data.blob.core.windows.net/"
    purpose       = "data"
  }
  "logs" = {
    name          = "stacmeprodeus001logs"
    id            = "/subscriptions/.../stacmeprodeus001logs"
    blob_endpoint = "https://stacmeprodeus001logs.blob.core.windows.net/"
    purpose       = "logs"
  }
}
```

## Backward Compatibility

**Breaking Change:** The boolean flags `enable_storage_account` and `enable_key_vault` have been removed.

**Migration Path:**

1. Old config:
```hcl
enable_storage_account = true
```

2. New config (creates one with "default" suffix):
```hcl
storage_accounts = {
  default = {
    tier              = "Standard"
    replication_type  = "LRS"
    blob_containers   = []
  }
}
```

Or better yet, use a descriptive name:
```hcl
storage_accounts = {
  main = {
    tier              = "Standard"
    replication_type  = "LRS"
    blob_containers   = []
  }
}
```

## Benefits

✅ **Better Organization** - Each resource has a clear purpose  
✅ **Easier Scaling** - Add new resources by adding map entries  
✅ **Flexible Configuration** - Each instance can have different settings  
✅ **Improved Tagging** - Auto-tagged with purpose from key  
✅ **Clearer Outputs** - See all resources organized by purpose  
✅ **Real-World Ready** - Matches how teams actually use Azure

## Next Steps

1. Read `MULTIPLE_INSTANCES_GUIDE.md` for detailed examples
2. Copy `deployments/_template` for your new customer
3. Configure your named instances in `terraform.tfvars`
4. Run `terraform plan` to preview resources
5. Run `terraform apply` to deploy!

## Questions?

Check the **"Common Questions"** section in `MULTIPLE_INSTANCES_GUIDE.md`.

---

**Updated**: November 2025  
**Template Version**: 2.0 (Multiple Named Instances)
