# Linux Virtual Machine

Creates one SSH-only Linux VM with a primary NIC, managed OS disk, boot
diagnostics, and system-assigned identity. Public IP and static private IP are
opt-in inputs; this module does not create a Public IP resource.

```hcl
module "vm" {
  source = "git::https://github.com/isaacrayner/TerraformTemplate.git//modules/virtual-machine?ref=v1.0.0"

  name                   = "vm-admin-contoso-prod-uks-001"
  network_interface_name = "nic-admin-contoso-prod-uks-001"
  location               = "uksouth"
  resource_group_name    = module.resource_groups.names["main"]
  subnet_id              = module.networking.subnet_ids["vms"]
  admin_ssh_public_key   = file("~/.ssh/id_ed25519.pub")
  tags                    = var.tags
}
```

The default image is Ubuntu 22.04 Gen2 with Secure Boot and vTPM enabled.
Override `source_image`, `secure_boot_enabled`, or `vtpm_enabled` together when
using an incompatible image/size. `admin_ssh_public_key` is key contents, not a
path. `custom_data` must already be base64-encoded.

Data disks, Public IP creation, backup, extensions, monitoring agents, and role
assignments have independent lifecycles and are composed outside this module.
