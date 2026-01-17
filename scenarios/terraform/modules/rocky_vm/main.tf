terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.6"  # ← Versión actualizada
    }
  }
}

provider "libvirt" {
  # uri = "qemu:///system"  # ← Comentada o eliminada si ya está en el módulo
}

module "vm" {
  source = "$ENGINE_DIR/scenarios/terraform/modules/rocky_vm"

  vm_name             = "$VM_NAME"
  base_image          = "$BASE_IMAGE"
  cloudinit_user_data = file("$CLOUDINIT_DIR/user-data")
  cloudinit_meta_data = file("$CLOUDINIT_DIR/meta-data")
}
EOF