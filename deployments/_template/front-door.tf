# Front Door + WAF — Landing Zone subscription (default provider)
# Global HTTP/S entry point that routes to Compute workloads (ACA, App Service)
# over their public hostnames. Private Link is not required for public-ingress
# backends.
#
# TO ENABLE:
#   1. Set enable_front_door = true in terraform.tfvars
#   2. Configure front_door_origin_groups and front_door_routes

module "front_door" {
  count  = var.enable_front_door ? 1 : 0
  source = "../../modules/front-door"

  name_suffix         = local.name_prefix
  resource_group_name = local.shared_resource_group_name

  sku_name                 = var.front_door_sku_name
  response_timeout_seconds = var.front_door_response_timeout_seconds

  endpoints     = var.front_door_endpoints
  origin_groups = var.front_door_origin_groups
  routes        = var.front_door_routes

  enable_waf            = var.enable_waf
  waf_mode              = var.waf_mode
  waf_managed_rule_sets = var.waf_managed_rule_sets
  waf_custom_rules      = var.waf_custom_rules

  tags = var.tags
}

module "diag_front_door" {
  count  = var.enable_front_door && local.diagnostics_enabled ? 1 : 0
  source = "../../modules/diagnostic-setting"

  name                       = "diag-${module.front_door[0].profile_name}"
  target_resource_id         = module.front_door[0].profile_id
  log_analytics_workspace_id = local.log_analytics_workspace_id
}
