# scenarios/terraform/modules/rocky_vm/main.tf

resource "libvirt_volume" "lab_disk" {
  name           = "${var.vm_name}.qcow2"
  pool           = var.disk_pool
  base_volume_id = var.base_image
  format         = "qcow2"
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name      = "${var.vm_name}-cloudinit.iso"
  pool      = var.disk_pool

  user_data = var.cloudinit_user_data
  meta_data = var.cloudinit_meta_data
}

resource "libvirt_domain" "lab_vm" {
  name   = var.vm_name
  memory = var.memory
  vcpu   = var.vcpus

  disk {
    volume_id = libvirt_volume.lab_disk.id
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit.id

  network_interface {
    network_name = var.network
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "none"
  }
}
