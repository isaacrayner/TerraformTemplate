# Redis Cache Module

resource "azurerm_redis_cache" "redis" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  capacity = var.capacity
  family   = var.family
  sku_name = var.sku_name

  non_ssl_port_enabled = var.non_ssl_port_enabled
  minimum_tls_version  = var.minimum_tls_version

  public_network_access_enabled = var.public_network_access_enabled

  redis_configuration {
    maxmemory_policy = var.maxmemory_policy
  }

  lifecycle {
    precondition {
      condition     = var.family != "P" || var.sku_name == "Premium"
      error_message = "family = \"P\" requires sku_name = \"Premium\"."
    }
  }

  tags = var.tags
}

# Firewall rules — only meaningful when the cache has a public endpoint
resource "azurerm_redis_firewall_rule" "firewall_rules" {
  for_each = var.public_network_access_enabled ? { for rule in var.allowed_ip_ranges : rule.name => rule } : {}

  name                = each.value.name
  redis_cache_name    = azurerm_redis_cache.redis.name
  resource_group_name = var.resource_group_name
  start_ip            = each.value.start_ip
  end_ip              = each.value.end_ip
}
