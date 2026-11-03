# Output Values for Redis Cache Module

output "redis_cache_id" {
  description = "Redis Cache resource ID"
  value       = azurerm_redis_cache.redis.id
}

output "redis_cache_name" {
  description = "Redis Cache name"
  value       = azurerm_redis_cache.redis.name
}

output "hostname" {
  description = "Redis Cache hostname"
  value       = azurerm_redis_cache.redis.hostname
}

output "ssl_port" {
  description = "TLS port (6380)"
  value       = azurerm_redis_cache.redis.ssl_port
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_redis_cache.redis.primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string"
  value       = azurerm_redis_cache.redis.primary_connection_string
  sensitive   = true
}
