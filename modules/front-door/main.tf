# Azure Front Door Standard/Premium + WAF Module
# Uses azurerm_cdn_frontdoor_* resources (AFD v2 — not the legacy azurerm_frontdoor_*)
#
# Per CONVENTIONS.md #1, names come from the caller (var.name_suffix, computed
# in the root's locals) and the resource group from the resource-group module.
# This module creates no resource group of its own. Front Door is a global
# service, so the profile has no location.

locals {
  profile_name = "fd-${var.name_suffix}"
  # WAF policy names: alphanumeric only, max 128 chars
  waf_name = "waf${replace(var.name_suffix, "/[^0-9A-Za-z]/", "")}"

  # Flatten origin_groups[*].origins into a single for_each-able map.
  # Key: "{group_key}-{origin_key}" — e.g. "api-primary", "frontend-secondary"
  origins_flat = merge([
    for group_key, group in var.origin_groups : {
      for origin_key, origin in group.origins :
      "${group_key}-${origin_key}" => merge(origin, {
        group_key  = group_key
        origin_key = origin_key
      })
    }
  ]...)

  # WAF is only meaningful when enabled and SKU supports it
  create_waf = var.enable_waf
  # Managed rule sets are silently skipped for Standard SKU (provider enforces this at apply time)
  waf_managed_rules = var.sku_name == "Premium_AzureFrontDoor" ? var.waf_managed_rule_sets : []
}

# =====================================================
# FRONT DOOR PROFILE
# =====================================================

resource "azurerm_cdn_frontdoor_profile" "profile" {
  name                     = local.profile_name
  resource_group_name      = var.resource_group_name
  sku_name                 = var.sku_name
  response_timeout_seconds = var.response_timeout_seconds
  tags                     = var.tags
}

# =====================================================
# ENDPOINTS
# Each endpoint gets a unique {name}.z01.azurefd.net FQDN.
# =====================================================

resource "azurerm_cdn_frontdoor_endpoint" "endpoints" {
  for_each = var.endpoints

  name                     = "fde-${each.key}-${var.name_suffix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id
  enabled                  = each.value.enabled
  tags                     = var.tags
}

# =====================================================
# ORIGIN GROUPS
# Each group has its own health probe and load balancing settings.
# =====================================================

resource "azurerm_cdn_frontdoor_origin_group" "groups" {
  for_each = var.origin_groups

  name                                                      = "og-${each.key}"
  cdn_frontdoor_profile_id                                  = azurerm_cdn_frontdoor_profile.profile.id
  session_affinity_enabled                                  = each.value.session_affinity_enabled
  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 10

  health_probe {
    interval_in_seconds = each.value.health_probe_interval_seconds
    path                = each.value.health_probe_path
    protocol            = each.value.health_probe_protocol
    request_type        = "HEAD"
  }

  load_balancing {
    sample_size                        = each.value.load_balancing_sample_size
    successful_samples_required        = each.value.load_balancing_successful_samples_required
    additional_latency_in_milliseconds = each.value.load_balancing_additional_latency_ms
  }
}

# =====================================================
# ORIGINS
# Flattened from origin_groups[*].origins so each VM/service is its own resource.
# =====================================================

resource "azurerm_cdn_frontdoor_origin" "origins" {
  for_each = local.origins_flat

  name                          = each.value.origin_key
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.groups[each.value.group_key].id

  enabled                        = each.value.enabled
  host_name                      = each.value.host_name
  http_port                      = each.value.http_port
  https_port                     = each.value.https_port
  origin_host_header             = coalesce(each.value.origin_host_header, each.value.host_name)
  priority                       = each.value.priority
  weight                         = each.value.weight
  certificate_name_check_enabled = each.value.certificate_name_check_enabled
}

# =====================================================
# ROUTES
# Routes wire an endpoint to an origin group with URL pattern + protocol rules.
# =====================================================

resource "azurerm_cdn_frontdoor_route" "routes" {
  for_each = var.routes

  name                          = "route-${each.key}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoints[each.value.endpoint_key].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.groups[each.value.origin_group_key].id

  # Include all origins that belong to this route's origin group
  cdn_frontdoor_origin_ids = [
    for k, v in local.origins_flat :
    azurerm_cdn_frontdoor_origin.origins[k].id
    if v.group_key == each.value.origin_group_key
  ]

  patterns_to_match      = each.value.patterns_to_match
  supported_protocols    = each.value.supported_protocols
  https_redirect_enabled = each.value.https_redirect
  forwarding_protocol    = each.value.forwarding_protocol
  link_to_default_domain = true

  dynamic "cache" {
    for_each = each.value.cache_enabled ? [1] : []
    content {
      query_string_caching_behavior = each.value.cache_query_string_caching_behavior
      compression_enabled           = true
    }
  }

  depends_on = [azurerm_cdn_frontdoor_origin.origins]
}

# =====================================================
# WAF POLICY
# Created when enable_waf = true.
# Managed rule sets (OWASP/Bot) only fire for Premium SKU (local.waf_managed_rules is [] for Standard).
# =====================================================

resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {
  count = local.create_waf ? 1 : 0

  name                = local.waf_name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  enabled             = true
  mode                = var.waf_mode
  tags                = var.tags

  # Microsoft-managed rule sets — OWASP Top 10 + Bot Manager (Premium only)
  dynamic "managed_rule" {
    for_each = { for i, rs in local.waf_managed_rules : tostring(i) => rs }
    content {
      type    = managed_rule.value.type
      version = managed_rule.value.version
      action  = managed_rule.value.action

      dynamic "override" {
        for_each = managed_rule.value.overrides
        content {
          rule_group_name = override.value.rule_group_name

          dynamic "rule" {
            for_each = override.value.rules
            content {
              rule_id = rule.value.rule_id
              enabled = rule.value.enabled
              action  = rule.value.action
            }
          }
        }
      }
    }
  }

  # Custom rules (Standard + Premium)
  dynamic "custom_rule" {
    for_each = var.waf_custom_rules
    content {
      name     = custom_rule.key
      enabled  = true
      priority = custom_rule.value.priority
      type     = custom_rule.value.rule_type
      action   = custom_rule.value.action

      rate_limit_duration_in_minutes = custom_rule.value.rule_type == "RateLimitRule" ? custom_rule.value.rate_limit_duration_in_minutes : null
      rate_limit_threshold           = custom_rule.value.rule_type == "RateLimitRule" ? custom_rule.value.rate_limit_threshold : null

      dynamic "match_condition" {
        for_each = custom_rule.value.match_conditions
        content {
          match_variable     = match_condition.value.match_variable
          operator           = match_condition.value.operator
          match_values       = match_condition.value.match_values
          selector           = match_condition.value.selector
          negation_condition = match_condition.value.negation_condition
          transforms         = match_condition.value.transforms
        }
      }
    }
  }
}

# =====================================================
# WAF SECURITY POLICY
# Attaches the WAF policy to all endpoints.
# =====================================================

resource "azurerm_cdn_frontdoor_security_policy" "waf_attach" {
  count = local.create_waf ? 1 : 0

  name                     = "secpol-${var.name_suffix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.waf[0].id

      association {
        # Protect every endpoint with the WAF policy
        dynamic "domain" {
          for_each = azurerm_cdn_frontdoor_endpoint.endpoints
          content {
            cdn_frontdoor_domain_id = domain.value.id
          }
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}
