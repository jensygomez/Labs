output "nodes" {
  value = {
    for k, v in var.containers : k => {
      name = k
      ip   = v.ip
      role = v.role
    }
  }
}
