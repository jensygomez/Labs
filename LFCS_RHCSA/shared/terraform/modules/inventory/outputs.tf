output "filename" {
  description = "Ruta absoluta del archivo de inventario generado"
  value       = local_file.ansible_inventory.filename
}
