variable "name" {
  description = "Private endpoint name, e.g. pep-blob-contoso-prod-uks-001. Compute this in the calling root — see CONVENTIONS.md."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  description = "PE subnet ID. That subnet must have private endpoint network policies disabled."
  type        = string
}

variable "target_resource_id" {
  description = "Resource ID of the PaaS service to expose privately."
  type        = string
}

variable "subresource_names" {
  description = "Sub-resource names for the target service, e.g. [\"vault\"], [\"blob\"], [\"sqlServer\"]. See README for the reference table."
  type        = list(string)
}

variable "private_dns_zone_ids" {
  description = "Private DNS zone IDs to register this endpoint in (from the private-dns-zone module). Empty list = no automatic DNS registration."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
