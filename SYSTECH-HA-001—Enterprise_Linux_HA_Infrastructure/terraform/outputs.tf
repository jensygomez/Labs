output "cluster_ip_addresses" {
  description = "Direcciones IP estáticas asignadas a cada nodo del clúster"
  value = {
    for k, v in proxmox_virtual_environment_vm.almalinux_cluster :
    k => try(
      # Intenta obtener la IP estática configurada en cloud-init
      [for ip in v.initialization[0].ip_config[0].ipv4 : split("/", ip.address)[0]][0],
      # Fallback: primera IP del agente que no sea loopback
      [for ip in v.ipv4_addresses : ip if ip != "127.0.0.1"][0],
      "IP no disponible aún"
    )
  }
}

output "lxc_ip_addresses" {
  description = "Direcciones IP asignadas a cada contenedor LXC"
  value = {
    for k, v in proxmox_virtual_environment_container.lxc_cluster :
    k => split("/", v.initialization[0].ip_config[0].ipv4[0].address)[0]
  }
}
