locals {
  ssh_pubkey   = trimspace(file(pathexpand("~/.ssh/id_lxd_fleet.pub")))
  fakecloud_ip = "10.45.223.1"

  vm_image  = "almalinux9-vm-std"    # ← CAMBIAR AQUÍ
  lxc_image = "almalinux9-cloud"     # El cliente LXC sigue igual
}

# ⚠️ ESTE BLOQUE FALTABA:
variable "app_count" {
  description = "Número de VMs de aplicación"
  type        = number
  default     = 3
}
