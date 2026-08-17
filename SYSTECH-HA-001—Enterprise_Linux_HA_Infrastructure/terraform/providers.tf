terraform {
  required_version = ">= 1.6.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.60.0"
    }
  }
}

variable "proxmox_ssh_private_key" {
  type        = string
  sensitive   = true
  description = "Contenido de la llave privada SSH para subir snippets a Proxmox"
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = true

  ssh {
    agent       = false
    username    = "root"
    private_key = var.proxmox_ssh_private_key # ← Usa variable directa, no file()
  }
}
