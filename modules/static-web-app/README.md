# Static Web App Module

This module creates an Azure Static Web App for hosting modern web applications with built-in CI/CD.

## Features

- Static Web App hosting
- Free, Standard, or Premium SKU
- Custom domain support
- Built-in authentication
- API integration (Azure Functions)
- Staging environments
- Global CDN distribution
- Automatic SSL certificates
- GitHub/Azure DevOps integration

## Usage

```hcl
module "static_web_app" {
  source = "../../modules/static-web-app"
  
  customer_short_name = var.customer_short_name
  environment         = var.environment
  location            = var.location
  location_code       = var.location_code
  resource_group_name = azurerm_resource_group.main.name
  
  sku_tier = "Standard"
  
  # GitHub Integration (optional)
  enable_github_integration = true
  github_repository_url     = "https://github.com/organization/repo"
  github_branch             = "main"
  
  # App Configuration
  app_settings = {
    "REACT_APP_API_URL" = "https://api.example.com"
  }
  
  # Custom Domain (optional)
  custom_domains = [
    "www.example.com",
    "example.com"
  ]
  
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

### Optional Variables

- `instance_number` - Instance number for naming (default: 1)
- `sku_tier` - SKU tier (default: "Free")
  - Options: Free, Standard
- `app_settings` - Application settings (default: {})
- `enable_github_integration` - Enable GitHub Actions workflow (default: false)
- `github_repository_url` - GitHub repository URL
- `github_branch` - GitHub branch name (default: "main")
- `custom_domains` - List of custom domain names
- `app_location` - App source code location (default: "/")
- `api_location` - API source code location (default: "api")
- `output_location` - Build output location (default: "build")
- `tags` - Resource tags

## Outputs

- `static_web_app_id` - Static Web App resource ID
- `static_web_app_name` - Static Web App name
- `default_hostname` - Default hostname (.azurestaticapps.net)
- `api_key` - Deployment token (sensitive)
- `custom_domain_verification_id` - Custom domain verification ID

## Resource Naming

Resources created by this module follow the naming convention:

- Static Web App: `stapp-{customer}-{env}-{region}-{instance}`

## SKU Comparison

| Feature | Free | Standard |
|---------|------|----------|
| **Bandwidth** | 100 GB/month | 100 GB/month (then pay-as-you-go) |
| **Custom Domains** | 2 | Unlimited |
| **SSL Certificates** | Automatic | Automatic |
| **Staging Environments** | 3 | Unlimited |
| **Authentication** | Built-in providers | Built-in + custom |
| **SLA** | None | 99.95% |
| **Functions** | Managed (limited) | Bring your own (unlimited) |

## Authentication Providers

Static Web Apps support built-in authentication with:
- Azure Active Directory
- GitHub
- Twitter
- Google (Standard tier only)
- Custom OpenID Connect (Standard tier only)

## Deployment Workflow

1. **Build Configuration**: Configure `app_location`, `api_location`, `output_location`
2. **Source Control**: Connect to GitHub or Azure DevOps
3. **Automatic Builds**: Commits trigger automatic builds and deployments
4. **Staging Environments**: Pull requests create staging environments
5. **Custom Domains**: Add and verify custom domains
6. **SSL Certificates**: Automatically provisioned and renewed

## Security Considerations

- Enable authentication for protected routes
- Use managed identities for API backend
- Configure allowed roles for route authorization
- Use custom domains with validated ownership
- Enable diagnostic logging
- Review and restrict allowed origins for APIs
- Use environment variables for sensitive configuration
- Never commit API keys to source control

## Dependencies

- Requires GitHub repository (for GitHub integration)
- Requires GitHub token with repo permissions
- Custom domains require DNS configuration
- API backend can use Azure Functions or other services

## Notes

- Free tier includes 100 GB bandwidth per month
- Staging environments auto-delete after PR merge
- Build time depends on app complexity (typically 2-5 minutes)
- Global CDN included automatically
- Supports SPAs (React, Angular, Vue, etc.)
- Supports static site generators (Hugo, Jekyll, Next.js, etc.)
- Functions runtime limited to 10 seconds in Free tier
- Consider upgrading to Standard for production workloads

## Example Frameworks

This module works with:
- **React**: Create React App, Next.js
- **Angular**: Angular CLI
- **Vue**: Vue CLI, Nuxt.js
- **Static Site Generators**: Hugo, Jekyll, Gatsby
- **Blazor**: Blazor WebAssembly
