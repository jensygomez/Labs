# scenarios/terraform/modules/rocky_vm/main.tf
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.6"
    }
  }
}

# Variables de entrada
variable "vm_name" {
  type = string
}

variable "base_image" {
  type = string
}

variable "cloudinit_user_data" {
  type = string
}

variable "cloudinit_meta_data" {
  type = string
}

# Recursos
resource "libvirt_volume" "lab_disk" {
  name   = "${var.vm_name}.qcow2"
  pool   = "default"
  source = var.base_image
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name      = "${var.vm_name}-seed.iso"
  pool      = "default"
  user_data = var.cloudinit_user_data
  meta_data = var.cloudinit_meta_data
}

resource "libvirt_domain" "lab_vm" {
  name   = var.vm_name
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.cloudinit.id

  disk {
    volume_id = libvirt_volume.lab_disk.id
  }

  network_interface {
    network_name = "default"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}