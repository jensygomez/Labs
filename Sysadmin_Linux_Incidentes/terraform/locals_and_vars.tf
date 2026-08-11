locals {
  ssh_pubkey   = trimspace(file(pathexpand("~/.ssh/id_lxd_fleet.pub")))
  fakecloud_ip = "10.45.223.1"
  
  # Imagen base. Si tienes un alias local 'almalinux9-cloud', cámbialo aquí.
  # Para VMs, LXD requiere imágenes con soporte UEFI.
  vm_image  = "images:almalinux/9/cloud"  # Esta ya tienes como VIRTUAL-MACHINE
  lxc_image = "almalinux9-cloud"          # Tu alias local para CONTAINER
}

variable "app_count" {
  default = 3
}
