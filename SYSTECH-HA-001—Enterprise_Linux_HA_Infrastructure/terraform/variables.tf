# variables.tf

variable "ssh_public_key" {
  description = "Clave pública SSH para inyectar en los nodos"
  type        = string
}

variable "target_node" {
  description = "Nombre del nodo Proxmox donde se crearán las VMs/LXCs"
  type        = string
  default     = "infra" # infra.systech.local
}

variable "proxmox_api_token" {
  description = "API Token de Proxmox para autenticación"
  type        = string
  sensitive   = true # ← Esto evita que se muestre en la consola
}
# Nodos LXC (Ubuntu 24.04)
variable "lxc_containers" {
  description = "Mapa de contenedores LXC a crear"
  type = map(object({
    vmid      = number
    ip        = string
    cores     = number
    memory    = number
    disk_size = number
    role      = string
  }))
  default = {
    "lb01"   = { vmid = 101, ip = "10.10.10.21/24", cores = 1, memory = 512, disk_size = 8, role = "lb" }
    "lb02"   = { vmid = 102, ip = "10.10.10.22/24", cores = 1, memory = 512, disk_size = 8, role = "lb" }
    "client" = { vmid = 111, ip = "10.10.10.11/24", cores = 1, memory = 512, disk_size = 8, role = "client" }
  }
}

# Nodos VM (AlmaLinux 9)
variable "cluster_nodes" {
  description = "Mapa de máquinas virtuales a crear"
  type = map(object({
    vmid        = number
    ip          = string
    cores       = number
    memory      = number
    extra_disks = list(number) # Ej: [10, 20] para discos adicionales
    role        = string
  }))
  default = {
    "app01"     = { vmid = 201, ip = "10.10.10.31/24", cores = 2, memory = 2048, extra_disks = [], role = "app" }
    "app02"     = { vmid = 202, ip = "10.10.10.32/24", cores = 2, memory = 2048, extra_disks = [], role = "app" }
    "app03"     = { vmid = 203, ip = "10.10.10.33/24", cores = 2, memory = 2048, extra_disks = [], role = "app" }
    "db01"      = { vmid = 301, ip = "10.10.10.40/24", cores = 2, memory = 4096, extra_disks = [20], role = "db" }
    "storage01" = { vmid = 401, ip = "10.10.10.50/24", cores = 2, memory = 2048, extra_disks = [10, 10, 10, 10], role = "storage" }
  }
}
