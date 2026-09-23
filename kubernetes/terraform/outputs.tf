output "vm_ips" {
  description = "IPs de las VMs del cluster de Kubernetes"
  value       = { for k, vm in proxmox_virtual_environment_vm.k8s_cluster : k => vm.ipv4_addresses }
}
