# variables.tf

variable "proxmox_password" {
  description = "Contraseña de root@pam en Proxmox (necesaria para modificar feature flags de LXC vía ticket-auth)"
  type        = string
  sensitive   = true
}
variable "ssh_public_key" {
  description = "Clave pública SSH para inyectar en los nodos"
  type        = string
}
variable "ssh_private_key" {
  description = "Clave privada SSH para que Terraform se autentique en Proxmox"
  type        = string
  sensitive   = true
}

variable "target_node" {
  description = "Nombre del nodo Proxmox donde se crearán las VMs/LXCs"
  type        = string
  default     = "infra" # infra.systech.local
}

variable "proxmox_api_token" {
  description = "API Token de Proxmox para autenticación"
  type        = string
  sensitive   = true
}

# Nodos LXC (Soporte Mixto: Ubuntu 24.04 / AlmaLinux 9)
variable "lxc_containers" {
  description = "Mapa de contenedores LXC a crear"
  type = map(object({
    vmid       = number
    ip         = string
    cores      = number
    memory     = number
    disk_size  = number
    role       = string
    privileged = optional(bool, false)
  }))
  default = {
    # CLIENTS (Ubuntu - No storage mounts -> Unprivileged)
    "client01" = { vmid = 111, ip = "10.10.10.11/24", cores = 1, memory = 512, disk_size = 8, role = "client" }
    "client02" = { vmid = 112, ip = "10.10.10.12/24", cores = 1, memory = 512, disk_size = 8, role = "client" }
    "client03" = { vmid = 113, ip = "10.10.10.13/24", cores = 1, memory = 512, disk_size = 8, role = "client" }

    # LOAD BALANCERS (Ubuntu - No storage mounts -> Unprivileged)
    "lb01" = { vmid = 221, ip = "10.10.10.21/24", cores = 1, memory = 1024, disk_size = 8, role = "lb" }
    "lb02" = { vmid = 222, ip = "10.10.10.22/24", cores = 1, memory = 1024, disk_size = 8, role = "lb" }

    # APP NODES (NFS Mounts -> Privileged + AlmaLinux 9)
    "app01" = { vmid = 331, ip = "10.10.10.31/24", cores = 2, memory = 512, disk_size = 8, role = "app", privileged = true }
    "app02" = { vmid = 332, ip = "10.10.10.32/24", cores = 2, memory = 512, disk_size = 8, role = "app", privileged = true }
    "app03" = { vmid = 333, ip = "10.10.10.33/24", cores = 2, memory = 512, disk_size = 8, role = "app", privileged = true }

    # DB NODE (iSCSI / Mounts -> Privileged + AlmaLinux 9)
    "db01" = { vmid = 440, ip = "10.10.10.40/24", cores = 2, memory = 1024, disk_size = 8, role = "db", privileged = true }
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
    extra_disks = list(number)
    role        = string
  }))
  default = {
    # Solo queda storage01 como VM real debido a su necesidad de múltiples discos
    "storage01" = { vmid = 550, ip = "10.10.10.50/24", cores = 2, memory = 2048, extra_disks = [10, 10, 10, 10], role = "storage" }
  }
}
