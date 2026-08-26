# terraform/test_instance.tf

resource "incus_instance" "test_node" {
  name      = "test-lb01"
  image     = "images:ubuntu/24.04"
  type      = "container" 
  profiles  = ["default"]
  ephemeral = false

  # Configuramos la interfaz de red para usar incusbr0
  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "incusbr0"
      name    = "eth0"
    }
  }
}

# Esto nos mostrará la IP asignada al finalizar
output "test_node_ip" {
  value = incus_instance.test_node.ipv4_address
}
