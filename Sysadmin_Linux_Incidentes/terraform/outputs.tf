output "app_vms_ips" {
  value = [for vm in libvirt_domain.app_vm : vm.network_interface[0].addresses[0]]
}

output "storage_vm_ip" {
  value = libvirt_domain.storage_vm.network_interface[0].addresses[0]
}

output "cliente_lxc_ip" {
  value = lxd_instance.cliente_lxc.ipv4_address
}

output "fakecloud_endpoints" {
  value = {
    s3      = "http://${local.fakecloud_ip}:4566"
    route53 = "http://${local.fakecloud_ip}:4566"
    elb     = aws_lb.app_alb.dns_name
  }
}
