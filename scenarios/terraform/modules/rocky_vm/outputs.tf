# scenarios/terraform/modules/rocky_vm/outputs.tf

output "vm_name" {
  value = libvirt_domain.lab_vm.name
}

output "vm_id" {
  value = libvirt_domain.lab_vm.id
}
