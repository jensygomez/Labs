variable "proxmox_api_url" {
  type        = string
  description = "URL de la API de Proxmox (ej: https://192.168.18.100:8006/)"
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "Token de Api de Proxmox (root@pam!tofu-token=...)"
}

variable "target_node" {
  type        = string
  default     = "homelab"
  description = "Nombre del nodo Proxmox donde se crearan las VMs"
}

variable "ssh_public_key" {
  type        = string
  description = "Clave pública SSH para inyectar via Cloud-Init en el usuario Ansible"
}

# ----------------------------------------------------------------------------
# Mapa para definir el cluster de VMs (workloads que necesitan kernel propio:
# LVM sobre discos crudos, iSCSI target/initiator)
#
# "role" determina a qué grupo de Ansible pertenece el nodo — agregar un nodo
# nuevo NUNCA requiere tocar inventory.tmpl, solo esta lista.
# ----------------------------------------------------------------------------
variable "cluster_nodes" {
  type = map(object({
    vmid        = number
    ip          = string
    cores       = number
    memory      = number
    extra_disks = list(number)
    role        = string # app | db | storage
  }))
  default = {
    "app01" = { vmid = 331, ip = "10.10.10.31/24", cores = 1, memory = 1536, extra_disks = [], role = "app" }
    "app02" = { vmid = 332, ip = "10.10.10.32/24", cores = 1, memory = 1536, extra_disks = [], role = "app" }
    "app03" = { vmid = 333, ip = "10.10.10.33/24", cores = 1, memory = 1536, extra_disks = [], role = "app" }

    "db01" = { vmid = 440, ip = "10.10.10.40/24", cores = 1, memory = 1536, extra_disks = [], role = "db" }

    "storage01" = { vmid = 550, ip = "10.10.10.50/24", cores = 1, memory = 1536, extra_disks = [1, 1, 1, 1], role = "storage" }
  }
}

# ----------------------------------------------------------------------------
# Mapa de contenedores LXC (workloads sin acceso a bloque crudo ni VRRP
# complicado: clientes NFS, balanceadores, monitoreo, tráfico de pruebas)
#
# Para agregar/quitar un contenedor: agregar/quitar una entrada acá.
# Para agregar un rol nuevo (grupo de Ansible nuevo): agregarlo también en
# local.role_group_map dentro de main.tf. Nada más.
# ----------------------------------------------------------------------------
variable "lxc_containers" {
  type = map(object({
    vmid      = number
    ip        = string
    cores     = number
    memory    = number
    disk_size = number
    role      = string # client | lb | monitoring
  }))
  default = {
    "client01" = { vmid = 111, ip = "10.10.10.11/24", cores = 1, memory = 512, disk_size = 8, role = "client" }
    "lb01"     = { vmid = 221, ip = "10.10.10.21/24", cores = 1, memory = 512, disk_size = 8, role = "lb" }
    "lb02"     = { vmid = 222, ip = "10.10.10.22/24", cores = 1, memory = 512, disk_size = 8, role = "lb" }
    "zabbix01" = { vmid = 990, ip = "10.10.10.90/24", cores = 1, memory = 1536, disk_size = 8, role = "monitoring" }
  }
}
