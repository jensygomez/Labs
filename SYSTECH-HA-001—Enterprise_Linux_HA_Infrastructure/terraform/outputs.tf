# outputs.tf

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    nodes = merge(
      {
        for k, vm in incus_instance.vm_cluster : k => {
          name = k
          ip   = var.cluster_nodes[k].ip
          role = var.cluster_nodes[k].role
        }
      },
      {
        for k, lxc in incus_instance.lxc_cluster : k => {
          name = k
          ip   = var.lxc_containers[k].ip
          role = var.lxc_containers[k].role
        }
      }
    )

    role_group_map = {
      app        = "app_nodes"
      db         = "db_nodes"
      storage    = "storage_nodes"
      lb         = "lb_nodes"
      client     = "client_nodes"
      monitoring = "monitoring_nodes"
      dns        = "dns_nodes"
    }
  })
  filename = "${path.module}/../ansible/inventories/production/hosts.yml"
}

output "infraestructura_desplegada" {
  value = {
    lxc = [
      for k, v in incus_instance.lxc_cluster :
      "${k} = ${try(v.ipv4_address, "N/A")}"
    ]
    vms = [
      for k, v in incus_instance.vm_cluster :
      "${k} = ${try(v.ipv4_address, "N/A")}"
    ]
  }
}
