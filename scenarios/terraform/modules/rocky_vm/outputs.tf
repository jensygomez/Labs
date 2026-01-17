output "vm_name" {
  value = var.vm_name
}

output "vm_id" {
  value = libvirt_domain.this.id
}
