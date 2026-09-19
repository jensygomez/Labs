terraform {
  required_version = ">= 1.6.0"
  required_providers {
    proxmox = { source = "bpg/proxmox"; version = ">= 0.50.0" }
    local   = { source = "hashicorp/local"; version = ">= 2.4.0" }
    null    = { source = "hashicorp/null"; version = ">= 3.2.0" }
  }
}

provider "proxmox" {
  endpoint = "https://${var.proxmox_host_ip}:8006/"
  username = "root@pam"
  password = var.proxmox_password
  insecure = true

  ssh {
    agent       = false
    username    = "root"
    private_key = var.ssh_private_key
    node {
      name    = var.target_node
      address = var.proxmox_host_ip
    }
  }
}
