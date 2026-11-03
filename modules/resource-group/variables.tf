variable "resource_groups" {
  description = "Map of resource groups to create. Key is a logical name (used elsewhere to reference this RG's id/name outputs); value has the exact name, location, and optional tags. Compute the exact name in the calling root's locals per CONVENTIONS.md naming — this module does not derive names itself."
  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string), {})
  }))
}

variable "tags" {
  description = "Default tags applied to every resource group (merged with per-RG tags)."
  type        = map(string)
  default     = {}
}
