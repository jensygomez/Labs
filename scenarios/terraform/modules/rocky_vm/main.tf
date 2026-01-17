resource "libvirt_cloudinit_disk" "this" {
  name      = "${var.vm_name}-cloudinit.iso"
  user_data = var.cloudinit_user_data
  meta_data = var.cloudinit_meta_data
}

resource "libvirt_domain" "this" {
  name   = var.vm_name
  memory = 2048
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.this.id

  disk {
    volume_id = libvirt_volume.root.id
  }

  network_interface {
    network_name = "default"
  }
}
