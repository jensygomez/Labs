# Descarga el template LXC de Ubuntu 24.04 (una sola vez, compartido por todos los contenedores)
resource "proxmox_download_file" "lxc_template" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = var.target_node
  url          = "http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  file_name    = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

# Cluster de contenedores LXC — for_each sobre var.lxc_containers
# Para agregar/quitar un LXC: solo edita el mapa "lxc_containers" en variables.tf
resource "proxmox_virtual_environment_container" "lxc_cluster" {
  for_each = var.lxc_containers

  node_name    = var.target_node
  vm_id        = each.value.vmid
  unprivileged = true
  started      = true

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = "local-lvm"
    size         = each.value.disk_size
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr1"
  }

  operating_system {
    template_file_id = proxmox_download_file.lxc_template.id
    type              = "ubuntu"
  }

  initialization {
    hostname = each.key

    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = "10.10.10.1"
      }
    }

    # El template LXC solo trae "root" por defecto; la llave se inyecta
    # a root aquí. El usuario "ansible" se crea después vía null_resource.
    user_account {
      keys = [var.ssh_public_key]
    }
  }

  features {
    nesting = true # útil si algún día quieres correr Docker dentro del LXC
  }

  start_on_boot = true
}

# ============================================================
# Provisioning del usuario "ansible" dentro de cada LXC
# (equivalente al "users:" del cloud-init que usan las VMs,
#  necesario porque el template LXC no soporta cloud-init user creation)
# ============================================================
resource "null_resource" "lxc_provision_user" {
  for_each = var.lxc_containers

  # Se re-ejecuta si el contenedor se recrea (nuevo id) o si cambia la llave pública
  triggers = {
    container_id = proxmox_virtual_environment_container.lxc_cluster[each.key].id
    ssh_key      = var.ssh_public_key
  }

  depends_on = [proxmox_virtual_environment_container.lxc_cluster]

  connection {
    type        = "ssh"
    host        = split("/", each.value.ip)[0]
    user        = "root"
    private_key = file("~/.ssh/id_systech_control")
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "useradd -m -s /bin/bash ansible || true",
      "mkdir -p /home/ansible/.ssh",
      "echo '${var.ssh_public_key}' > /home/ansible/.ssh/authorized_keys",
      "chown -R ansible:ansible /home/ansible/.ssh",
      "chmod 700 /home/ansible/.ssh",
      "chmod 600 /home/ansible/.ssh/authorized_keys",
      "echo 'ansible ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible",
      "chmod 440 /etc/sudoers.d/ansible",
    ]
  }
}

