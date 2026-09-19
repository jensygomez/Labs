resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    nodes          = var.nodes
    role_group_map = var.role_group_map
  })
  filename = var.output_path
}
