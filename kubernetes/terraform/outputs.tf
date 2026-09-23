output "inventory_file" {
  description  = "Ruta del inventario de Ansible generado"
  value        = module.inventory.filename
}
