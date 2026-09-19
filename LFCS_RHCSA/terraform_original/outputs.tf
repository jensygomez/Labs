# outputs.tf

output "inventory_file_path" {
  description = "Ruta del inventario de Ansible generado"
  value       = local_file.ansible_inventory.filename
}

output "vm_ips" {
  description = "Lista de IPs de las VMs creadas"
  value       = { for k, vm in proxmox_virtual_environment_vm.almalinux_cluster : k => vm.ipv4_addresses }
}
