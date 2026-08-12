locals {
  ssh_pubkey   = trimspace(file(pathexpand("~/.ssh/id_lxd_fleet.pub")))
  fakecloud_ip = "10.45.223.1"

  lxc_image = "almalinux9-cloud"

  libvirt_pool       = "default"
  libvirt_base_image = "/var/lib/libvirt/images/almalinux9-cloud-base.qcow2"
}

variable "app_count" {
  description = "Número de VMs de aplicación"
  type        = number
  default     = 3
}
