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

# Laboratorio activo: solo se crean las VMs cuyo campo "lab" coincida
variable "lab" {
  description = "Laboratorio a levantar: none, kubernetes, rhcsa o rhce"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "kubernetes", "rhcsa", "rhce"], var.lab)
    error_message = "El valor de lab debe ser: none, kubernetes, rhcsa o rhce."
  }
}

# Catálogo de TODAS las VMs de todos los labs (solo se crean las del lab activo)
variable "all_nodes" {
  description = "Mapa de VMs de todos los laboratorios, filtrado por var.lab"
  type = map(object({
    lab         = string
    vmid        = number
    ip          = string
    cores       = number
    memory      = number
    disk_size   = optional(number, 20)
    extra_disks = optional(list(number), [])
    role        = string
  }))
  default = {
    # --- Kubernetes ---
    "k8s-master"   = { lab = "kubernetes", vmid = 610, ip = "10.10.10.61/24", cores = 2, memory = 4096, role = "master" }
    "k8s-worker01" = { lab = "kubernetes", vmid = 611, ip = "10.10.10.62/24", cores = 2, memory = 4096, role = "worker" }
    "k8s-worker02" = { lab = "kubernetes", vmid = 612, ip = "10.10.10.63/24", cores = 2, memory = 4096, role = "worker" }

    # --- RHCSA: discos extra para practicar LVM, Stratis, swap, etc. ---
    "rhcsa-server1" = { lab = "rhcsa", vmid = 710, ip = "10.10.10.71/24", cores = 2, memory = 2048, extra_disks = [5, 5, 5], role = "server" }
    "rhcsa-server2" = { lab = "rhcsa", vmid = 711, ip = "10.10.10.72/24", cores = 2, memory = 2048, extra_disks = [5], role = "server" }

    # --- RHCE: nodos gestionados (el control node es tu contenedor) ---
    "rhce-node1" = { lab = "rhce", vmid = 811, ip = "10.10.10.82/24", cores = 1, memory = 1536, role = "managed" }
    "rhce-node2" = { lab = "rhce", vmid = 812, ip = "10.10.10.83/24", cores = 1, memory = 1536, role = "managed" }
    "rhce-node3" = { lab = "rhce", vmid = 813, ip = "10.10.10.84/24", cores = 1, memory = 1536, role = "managed" }
  }
}
