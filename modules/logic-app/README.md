# Logic App Module

This module creates an Azure Logic App for workflow automation and integration.

## Features

- Logic App Standard or Consumption tier
- Built-in and managed connectors
- Workflow automation
- Event-driven triggers
- Conditional logic and loops
- Integration with 400+ services
- Managed identity support
- Private endpoint support
- Diagnostic logging

## Usage

```hcl
module "logic_app" {
  source = "../../modules/logic-app"
  
  customer_short_name = var.customer_short_name
  environment         = var.environment
  location            = var.location
  location_code       = var.location_code
  resource_group_name = azurerm_resource_group.main.name
  
  # Logic App Standard (hosted in App Service Plan)
  logic_app_type = "Standard"
  
  # App Service Plan for Standard
  app_service_plan_id = module.app_service.plan_id
  
  # Storage account for Standard (required)
  storage_account_name       = module.storage_account.storage_account_name
  storage_account_access_key = module.storage_account.primary_access_key
  
  # Application Insights (optional)
  application_insights_key = module.monitoring.instrumentation_key
  
  # App Settings
  app_settings = {
    "WORKFLOWS_SUBSCRIPTION_ID"     = data.azurerm_client_config.current.subscription_id
    "WORKFLOWS_RESOURCE_GROUP_NAME" = azurerm_resource_group.main.name
  }
  
  # Managed Identity
  enable_system_assigned_identity = true
  
  tags = var.tags
}
```

## Consumption Tier Example

```hcl
module "logic_app_consumption" {
  source = "../../modules/logic-app"
  
  customer_short_name = var.customer_short_name
  environment         = var.environment
  location            = var.location
  location_code       = var.location_code
  resource_group_name = azurerm_resource_group.main.name
  
  logic_app_type = "Consumption"
  
  # Workflow definition
  workflow_definition = {
    "$schema" = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
    contentVersion = "1.0.0.0"
    triggers = {
      manual = {
        type = "Request"
        kind = "Http"
      }
    }
    actions = {
      Response = {
        type = "Response"
        inputs = {
          statusCode = 200
          body = "Hello from Logic App"
        }
      }
    }
  }
  
  tags = var.tags
}
```

## Variables

### Required Variables

- `customer_short_name` - Short name for the customer (3-8 characters)
- `environment` - Environment name (prod, dev, staging)
- `location` - Azure region
- `location_code` - Short region code (eus, wus, etc.)
- `resource_group_name` - Name of the resource group
- `logic_app_type` - Type of Logic App (Standard or Consumption)

### Standard Tier Variables

- `app_service_plan_id` - App Service Plan ID (required for Standard)
- `storage_account_name` - Storage account name (required for Standard)
- `storage_account_access_key` - Storage account key (required for Standard)

### Optional Variables

- `instance_number` - Instance number for naming (default: 1)
- `workflow_definition` - Workflow JSON definition (Consumption tier)
- `app_settings` - Application settings
- `enable_system_assigned_identity` - Enable system-assigned managed identity (default: true)
- `user_assigned_identity_ids` - User-assigned identity IDs
- `application_insights_key` - Application Insights instrumentation key
- `enable_https_only` - Enforce HTTPS only (default: true)
- `virtual_network_subnet_id` - Subnet ID for VNet integration
- `tags` - Resource tags

## Outputs

- `logic_app_id` - Logic App resource ID
- `logic_app_name` - Logic App name
- `principal_id` - Managed identity principal ID
- `default_hostname` - Logic App hostname
- `workflow_endpoint` - Workflow HTTP endpoint (Consumption)
- `outbound_ip_addresses` - Outbound IP addresses

## Resource Naming

Resources created by this module follow the naming convention:

- Logic App Standard: `logic-{customer}-{env}-{region}-{instance}`
- Logic App Consumption: `logic-{customer}-{env}-{region}-{instance}`

## Standard vs Consumption Comparison

| Feature | Consumption | Standard |
|---------|------------|----------|
| **Hosting** | Multi-tenant | App Service Plan |
| **Pricing** | Per execution | Per plan |
| **VNet Integration** | Limited | Full support |
| **Private Endpoints** | No | Yes |
| **Local Development** | Limited | VS Code extension |
| **Stateful Workflows** | No | Yes |
| **Performance** | Variable | Dedicated resources |
| **DevOps** | Portal-based | Code-first (CI/CD) |

## Common Use Cases

### Data Integration
- Sync data between systems
- ETL/ELT pipelines
- Database triggers and updates
- File processing workflows

### Business Processes
- Approval workflows
- Order processing
- Invoice automation
- Customer onboarding

### Monitoring and Alerts
- Service health monitoring
- Automated incident response
- Log analysis and alerting
- Scheduled report generation

### API Orchestration
- API aggregation and composition
- Service orchestration
- Legacy system integration
- Event-driven microservices

## Built-in Connectors

Popular connectors include:
- **Azure Services**: Storage, SQL, Cosmos DB, Service Bus, Event Grid
- **Microsoft 365**: Outlook, SharePoint, Teams, OneDrive
- **Databases**: SQL Server, MySQL, PostgreSQL, Oracle
- **SaaS**: Salesforce, Dynamics 365, SAP, ServiceNow
- **Communication**: Twilio, SendGrid, SMTP
- **Social**: Twitter, Facebook, LinkedIn

## Security Considerations

- Use managed identities for Azure service connections
- Store connection strings in Key Vault
- Enable HTTPS only
- Configure IP restrictions for webhook triggers
- Use SAS tokens with short expiration
- Enable diagnostic logging
- Review and audit connector permissions
- Use private endpoints (Standard tier)
- Implement retry policies for transient failures

## Dependencies

### Standard Tier
- Requires App Service Plan (Workflow Standard WS1, WS2, WS3)
- Requires Storage Account (for workflow state and metadata)
- Optional: VNet for integration
- Optional: Application Insights for monitoring

### Consumption Tier
- No infrastructure dependencies
- Runs in multi-tenant environment

## Monitoring

Enable diagnostics to track:
- Workflow runs (success/failure)
- Action execution times
- Connector operations
- Throttling events
- Error details and exceptions

## Development Workflow

### Consumption Tier
1. Design workflows in Azure Portal
2. Use Logic App Designer (visual)
3. Export ARM templates for deployment
4. Test in portal or with HTTP tools

### Standard Tier
1. Develop locally with VS Code
2. Version control workflow definitions
3. Deploy via CI/CD pipelines
4. Use Application Insights for monitoring

## Notes

- Standard tier provides better performance for high-volume scenarios
- Consumption tier is cost-effective for infrequent workflows
- Standard tier supports stateful workflows for long-running processes
- Use managed identities instead of connection strings
- Consider API Management for exposing Logic Apps as APIs
- Standard tier requires storage account in same region
- Workflow definitions are JSON-based
- Built-in retry policies handle transient failures
- Maximum workflow duration: 90 days (Standard), 30 days (Consumption)

## Performance Considerations

- Standard tier provides dedicated compute resources
- Consumption tier may experience cold starts
- Use batching for high-volume operations
- Implement parallel processing with foreach loops
- Consider Event Grid for event-driven scenarios
- Monitor throttling limits per connector
- Use pagination for large data sets
