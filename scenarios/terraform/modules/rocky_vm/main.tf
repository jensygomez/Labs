terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.1"
    }
  }
}

# Cloud-init disk
resource "libvirt_cloudinit_disk" "this" {
  name           = "${var.vm_name}-cloudinit.iso"
  user_data      = var.cloudinit_user_data
  meta_data      = var.cloudinit_meta_data
}

# Root disk (FALTABA - clona tu imagen base)
resource "libvirt_volume" "root" {
  name   = "${var.vm_name}-root.qcow2"
  source = var.base_image
  format = "qcow2"
  pool   = "default"  # Asegúrate que existe esta storage pool
}

# VM definition
resource "libvirt_domain" "this" {
  name   = var.vm_name
  memory = 1024
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.this.id

  disk {
    volume_id = libvirt_volume.root.id
  }

  network_interface {
    network_name = "default"
  }

  # Autostart y console
  auto_start = true
  
  console {
    type        = "pty"
    target_port = "5900"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}
