terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}


resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    nodes          = var.nodes
    role_group_map = var.role_group_map
  })
  filename = var.output_path
}
