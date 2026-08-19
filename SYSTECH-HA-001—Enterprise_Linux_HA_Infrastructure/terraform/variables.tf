variable "proxmox_api_url" {
  type         = string
  description  = "URL de la API de Proxmox (ej: https://192.168.18.100:8006/)"
}

variable "proxmox_api_token" {
  type         = string
  sensitive    = true
  description  = "Token de Api de Proxmox (root@pam!tofu-token=...)" 
}

variable "target_node" {
  type         = string
  default      = "homelab"
  description  = "Nombre del nodo Proxmox donde se crearan las VMs"
}

variable "ssh_public_key" {
  type         = string 
  description  = "Clave pública SSH para inyectar via Cloud-Init en el usuario Ansible"
}

# Mapa para definir el cluster de 3 nodos
variable "cluster_nodes" {
  type = map(object({
    vmid   = number
    ip     = string
    cores  = number
    memory = number # AÑADIDO: Faltaba en la definición del objeto
  }))
  default = {
    "server01" = { vmid = 201, ip = "10.10.10.21/24", cores = 1, memory = 1536 }
    "server02" = { vmid = 202, ip = "10.10.10.22/24", cores = 1, memory = 1536 }
    "server03" = { vmid = 203, ip = "10.10.10.23/24", cores = 1, memory = 1536 }
  }
}

# Mapa de contenedores LXC - agregar/quitar entradas aqui, nada mas
variable "lxc_containers" {
  type = map(object({
    vmid          = number
    ip            = string
    cores         = number
    memory        = number
    disk_size     = number
  }))
  default = {
    "lb01" = { vmid = 301, ip = "10.10.10.31/24", cores = 1, memory = 512, disk_size = 8 }
    "lb02" = { vmid = 302, ip = "10.10.10.32/24", cores = 1, memory = 512, disk_size = 8 }
    "client" = { vmid = 303, ip = "10.10.10.33/24", cores = 1, memory = 512, disk_size = 8 }
}
}


