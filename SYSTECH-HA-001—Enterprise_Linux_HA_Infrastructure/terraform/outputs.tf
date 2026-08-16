output "cluster_ip_addresses" {
  description = "Direcciones IP asignadas a cada nodo del clúster"
  value = {
    # Usamos try() para evitar errores si el QEMU Guest Agent tarda en reportar la IP.
    # Si ipv4_addresses está vacío, hace fallback a la IP estática configurada.
    for k, v in proxmox_virtual_environment_vm.almalinux_cluster : 
      k => try(v.ipv4_addresses[0], v.initialization[0].ip_config[0].ipv4[0].address)
  }
}
