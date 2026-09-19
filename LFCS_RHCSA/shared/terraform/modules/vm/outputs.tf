output "nodes" {
  value = {
    for k, v in var.vms : k => {
      name = k
      ip   = v.ip
      role = v.role
    }
  }
}
