# Module: resource-group
# Creates one or more resource groups from a map. Raw azurerm (reliable, no
# provider-schema guesswork) — see CONVENTIONS.md "Why raw azurerm by default".

resource "azurerm_resource_group" "this" {
  for_each = var.resource_groups
  name     = each.value.name
  location = each.value.location
  tags     = merge(var.tags, try(each.value.tags, {}))
}
