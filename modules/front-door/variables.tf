# Input Variables — Azure Front Door + WAF Module

# =====================================================
# NAMING AND PLACEMENT (CONVENTIONS.md #1)
# =====================================================

variable "name_suffix" {
  description = "Naming suffix computed in the calling root's locals, e.g. local.name_prefix. Resources are named fd-{suffix}, fde-{endpoint key}-{suffix}, waf{suffix without hyphens} and secpol-{suffix}."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the Front Door profile and WAF policy. Create it with the resource-group module; this module does not create one."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =====================================================
# FRONT DOOR PROFILE
# =====================================================

variable "sku_name" {
  description = <<-EOT
    Front Door SKU:
    - "Standard_AzureFrontDoor"  — CDN, static acceleration, custom rules WAF only
    - "Premium_AzureFrontDoor"   — Adds Microsoft-managed WAF rule sets, Private Link origins, advanced security
    WAF managed rule sets (OWASP, Bot Manager) require Premium.
  EOT
  type        = string
  default     = "Premium_AzureFrontDoor"
  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.sku_name)
    error_message = "sku_name must be 'Standard_AzureFrontDoor' or 'Premium_AzureFrontDoor'."
  }
}

variable "response_timeout_seconds" {
  description = "Maximum time in seconds Front Door waits for a response from the origin (16–240)"
  type        = number
  default     = 120
  validation {
    condition     = var.response_timeout_seconds >= 16 && var.response_timeout_seconds <= 240
    error_message = "response_timeout_seconds must be between 16 and 240."
  }
}

# =====================================================
# ENDPOINTS
# Each endpoint exposes a unique {name}.z01.azurefd.net FQDN.
# Most deployments need only the "default" endpoint.
# =====================================================

variable "endpoints" {
  description = <<-EOT
    Map of Front Door endpoints. Key becomes part of the endpoint name.
    Most deployments only need one: endpoints = { default = {} }
    Add extra endpoints for multi-tenant or separate API/app surfaces.
  EOT
  type = map(object({
    enabled = optional(bool, true)
  }))
  default = { default = {} }
  validation {
    condition     = can([for k, v in var.endpoints : regex("^[a-z0-9-]{1,20}$", k)])
    error_message = "Endpoint keys must be 1-20 lowercase alphanumeric characters or hyphens."
  }
}

# =====================================================
# ORIGIN GROUPS & ORIGINS
# Origin groups hold one or more backend origins.
# Routes connect an endpoint to an origin group.
# =====================================================

variable "origin_groups" {
  description = <<-EOT
    Map of origin groups. Key is used as the group name suffix (e.g., "api", "frontend", "static").
    Each group contains one or more origins (backend servers/services).
    Typically one origin group per workload component.

    EXAMPLE:
      origin_groups = {
        frontend = {
          origins = {
            primary = { host_name = "myapp.azurecontainerapps.io" }
          }
        }
        api = {
          health_probe_path = "/health"
          origins = {
            primary   = { host_name = "myapi.azurecontainerapps.io", priority = 1, weight = 1000 }
            secondary = { host_name = "myapi-dr.azurecontainerapps.io", priority = 2, weight = 100 }
          }
        }
      }
  EOT
  type = map(object({
    session_affinity_enabled      = optional(bool, false)
    health_probe_path             = optional(string, "/")
    health_probe_protocol         = optional(string, "Https")
    health_probe_interval_seconds = optional(number, 100)
    # Load balancing settings
    load_balancing_sample_size                 = optional(number, 4)
    load_balancing_successful_samples_required = optional(number, 3)
    load_balancing_additional_latency_ms       = optional(number, 50)

    origins = map(object({
      host_name = string
      # origin_host_header: the Host header sent to the origin.
      # Default null = use host_name. Override when the origin expects a different Host header.
      origin_host_header             = optional(string, null)
      http_port                      = optional(number, 80)
      https_port                     = optional(number, 443)
      priority                       = optional(number, 1)
      weight                         = optional(number, 1000)
      enabled                        = optional(bool, true)
      certificate_name_check_enabled = optional(bool, true)
    }))
  }))
  default = {}
}

# =====================================================
# ROUTES
# A route wires one endpoint to one origin group with path/protocol rules.
# =====================================================

variable "routes" {
  description = <<-EOT
    Map of routes. Each route connects an endpoint to an origin group for matching URL patterns.
    Key is the route name suffix (e.g., "frontend", "api", "static").

    EXAMPLE — frontend catches everything, api catches /api/* first:
      routes = {
        api = {
          endpoint_key     = "default"
          origin_group_key = "api"
          patterns_to_match = ["/api/*"]
        }
        frontend = {
          endpoint_key     = "default"
          origin_group_key = "frontend"
          patterns_to_match = ["/*"]
        }
      }
  EOT
  type = map(object({
    endpoint_key     = string
    origin_group_key = string
    # patterns_to_match: URL path patterns. More specific patterns take priority.
    patterns_to_match   = optional(list(string), ["/*"])
    supported_protocols = optional(list(string), ["Http", "Https"])
    # https_redirect: redirect HTTP → HTTPS at the Front Door edge (recommended)
    https_redirect = optional(bool, true)
    # forwarding_protocol: protocol used between Front Door and the origin
    # "HttpsOnly" (recommended), "HttpOnly", "MatchRequest"
    forwarding_protocol = optional(string, "HttpsOnly")
    # cache_enabled: enable CDN caching for static content
    cache_enabled                       = optional(bool, false)
    cache_query_string_caching_behavior = optional(string, "IgnoreQueryString")
  }))
  default = {}
}

# =====================================================
# WAF (Web Application Firewall)
# Requires Premium_AzureFrontDoor for managed rule sets.
# Standard SKU supports custom rules only.
# =====================================================

variable "enable_waf" {
  description = "Enable Web Application Firewall policy. Managed rule sets require Premium SKU."
  type        = bool
  default     = true
}

variable "waf_mode" {
  description = <<-EOT
    WAF operation mode:
    - "Prevention" — actively blocks matched requests (use in production)
    - "Detection"  — logs matched requests without blocking (use for initial tuning)
  EOT
  type        = string
  default     = "Prevention"
  validation {
    condition     = contains(["Prevention", "Detection"], var.waf_mode)
    error_message = "waf_mode must be 'Prevention' or 'Detection'."
  }
}

variable "waf_managed_rule_sets" {
  description = <<-EOT
    Microsoft-managed WAF rule sets. Requires Premium SKU.
    - Microsoft_DefaultRuleSet 2.1  — OWASP Top 10, SQLi, XSS, LFI, RFI, etc.
    - Microsoft_BotManagerRuleSet 1.0 — bot detection and mitigation

    To disable a specific rule, add an override entry.
    Set to [] to use custom rules only (Standard SKU compatible).
  EOT
  type = list(object({
    type    = string
    version = string
    # action: what the rule set does on a match; required by azurerm 4.x
    # ("Block", "Log", "Allow", "Redirect").
    action = optional(string, "Block")
    overrides = optional(list(object({
      rule_group_name = string
      rules = optional(list(object({
        rule_id = string
        enabled = bool
        # action: "Allow", "AnomalyScoring", "Block", "Log", "Redirect"
        action = string
      })), [])
    })), [])
  }))
  default = [
    { type = "Microsoft_DefaultRuleSet", version = "2.1", overrides = [] },
    { type = "Microsoft_BotManagerRuleSet", version = "1.0", overrides = [] }
  ]
}

variable "waf_custom_rules" {
  description = <<-EOT
    Custom WAF rules evaluated before managed rule sets.
    Supports IP blocking, geo-filtering, rate limiting, and header/URI matching.

    EXAMPLES:
      waf_custom_rules = {
        # Block specific IP ranges
        BlockBadIPs = {
          priority = 100
          rule_type = "MatchRule"
          action    = "Block"
          match_conditions = [{
            match_variable = "RemoteAddr"
            operator       = "IPMatch"
            match_values   = ["192.168.1.0/24", "10.99.0.0/16"]
          }]
        }
        # Rate limit all traffic to 1000 req/min per IP
        RateLimitAll = {
          priority = 200
          rule_type = "RateLimitRule"
          action    = "Block"
          rate_limit_threshold           = 1000
          rate_limit_duration_in_minutes = 1
          match_conditions = [{
            match_variable = "RemoteAddr"
            operator       = "IPMatch"
            match_values   = ["0.0.0.0/0"]
          }]
        }
        # Geo-block specific countries
        GeoBlock = {
          priority = 300
          rule_type = "MatchRule"
          action    = "Block"
          match_conditions = [{
            match_variable = "RemoteAddr"
            operator       = "GeoMatch"
            match_values   = ["CN", "RU", "KP"]
          }]
        }
      }
  EOT
  type = map(object({
    priority  = number
    rule_type = string # "MatchRule" or "RateLimitRule"
    action    = string # "Allow", "Block", "Log", "Redirect"
    match_conditions = list(object({
      match_variable     = string # "RemoteAddr", "RequestUri", "RequestHeader", "QueryString", "PostArgs", "RequestBody", "RequestMethod", "RequestScheme"
      operator           = string # "IPMatch", "GeoMatch", "Equal", "Contains", "LessThan", "GreaterThan", "BeginsWith", "EndsWith", "RegEx", "Any"
      match_values       = list(string)
      selector           = optional(string) # required for RequestHeader, RequestCookie, QueryString, PostArgs
      negation_condition = optional(bool, false)
      transforms         = optional(list(string), []) # "Lowercase", "Uppercase", "Trim", "UrlDecode", "UrlEncode", "RemoveNulls"
    }))
    rate_limit_duration_in_minutes = optional(number, 1)
    rate_limit_threshold           = optional(number, 1000)
  }))
  default = {}
}
