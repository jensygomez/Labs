# providers.tf
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

#provider "proxmox" {
#  endpoint  = "https://100.93.29.93:8006/"
#  api_token = var.proxmox_api_token
#  insecure  = true
#
#  # ✅ BLOQUE SSH AGREGADO: Le dice al provider cómo conectarse por SSH
#  ssh {
#    agent       = false
#    username    = "root"
#    private_key = var.ssh_private_key
#
#    node {
#      name    = "infra"
#      address = "100.93.29.93"
#    }
#  }
#}

provider "proxmox" {
  endpoint = "https://100.93.29.93:8006/"
  username = "root@pam"
  password = var.proxmox_password
  insecure = true

  ssh {
    agent       = false
    username    = "root"
    private_key = var.ssh_private_key

    node {
      name    = "infra"
      address = "100.93.29.93"
    }
  }
}
