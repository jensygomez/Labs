locals {
  ssh_pubkey   = trimspace(file(pathexpand("~/.ssh/id_lxd_fleet.pub")))
  fakecloud_ip = "10.45.223.1"
  
  # Imágenes locales (ya las tienes en tu LXD)
  vm_image  = "almalinux9-vm-cloud"   # Para VMs (UEFI)
  lxc_image = "almalinux9-cloud"      # Para contenedores
}

# ⚠️ ESTE BLOQUE FALTABA:
variable "app_count" {
  description = "Número de VMs de aplicación"
  type        = number
  default     = 3
}
