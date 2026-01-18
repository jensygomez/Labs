# scenarios/terraform/modules/rocky_vm/main.tf

terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.6"
    }
  }
}

provider "libvirt" {}

module "lab_vm" {
  source = "$ENGINE_DIR/scenarios/terraform/modules/rocky_vm"

  lab_name      = "$VM_NAME"
  base_image    = "$BASE_IMAGE"
  cloudinit_iso = "$CLOUDINIT_DIR/user-data"
}