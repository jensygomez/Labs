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
