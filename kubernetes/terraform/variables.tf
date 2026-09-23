variable "proxmox_api_token" {
  type      = string
  sensitive = true
  default   = "" # no lo usa el provider (auth es por password), se mantiene por compatibilidad con entrypoint.sh
}

variable "proxmox_password" {
  description = "Contraseña de root@pam en Proxmox"
  type        = string
  sensitive   = true
}

variable "target_node" {
  type    = string
  default = "infra"
}

variable "proxmox_host_ip" {
  type    = string
  default = "100.93.29.93"
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "ssh_private_key" {
  type      = string
  sensitive = true
}

# Nodos del cluster de Kubernetes
variable "cluster_nodes" {
  description = "Mapa de VMs del cluster de Kubernetes (master + workers)"
  type = map(object({
    vmid        = number
    ip          = string
    cores       = number
    memory      = number
    disk_size   = optional(number, 20)
    extra_disks = optional(list(number), [])
    role        = string
  }))
  default = {
    "k8s-master"   = { vmid = 610, ip = "10.10.10.61/24", cores = 2, memory = 2048, role = "master" }
    "k8s-worker01" = { vmid = 611, ip = "10.10.10.62/24", cores = 2, memory = 4096, role = "worker" }
    "k8s-worker02" = { vmid = 612, ip = "10.10.10.63/24", cores = 2, memory = 4096, role = "worker" }
  }
}
