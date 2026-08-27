terraform {
  required_version = ">= 1.6.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.50.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://100.93.29.93:8006/" # IP de Taiscale
  api_token = var.proxmox_api_token        # la que está en Vault
  insecure  = true                         # solo para pruebas, después cámbialo a false
}
