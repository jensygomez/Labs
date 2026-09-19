# 1. Crear el LXC de práctica llamando al módulo compartido
module "practice_lxc" {
  source = "../../shared/terraform/modules/lxc"

  target_node     = var.target_node
  proxmox_host_ip = var.proxmox_host_ip
  ssh_public_key  = var.ssh_public_key
  ssh_private_key = var.ssh_private_key

  containers = {
    "lf-practice" = {
      vmid      = 900
      ip        = "10.10.10.90/24"
      cores     = 2
      memory    = 2048
      disk_size = 10
      role      = "lfcs"
    }
  }
}

# 2. Generar el inventario de Ansible automáticamente
module "inventory" {
  source = "../../shared/terraform/modules/inventory"

  nodes = module.practice_lxc.nodes # ¡Reutiliza la salida del módulo LXC!

  role_group_map = {
    lfcs = "lfcs_nodes"
  }

  output_path = "${path.module}/../ansible/inventories/production/hosts.yml"
}
