output "vm_ips" {
  description = "IPs de las VMs del laboratorio activo"
  value       = { for k, vm in proxmox_virtual_environment_vm.lab_vms : k => vm.ipv4_addresses }
}
