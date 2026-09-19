# Template LXC AlmaLinux 9 (Servidor oficial de Proxmox VE)
resource "proxmox_download_file" "lxc_template_almalinux" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = var.target_node
  url          = "http://download.proxmox.com/images/system/almalinux-9-default_20240911_amd64.tar.xz"
  file_name    = "almalinux-9-default_20240911_amd64.tar.xz"
  overwrite    = true
}

# Cluster de contenedores LXC en AlmaLinux 9
resource "proxmox_virtual_environment_container" "lxc_cluster" {
  for_each = var.lxc_containers

  node_name    = var.target_node
  vm_id        = each.value.vmid
  unprivileged = !each.value.privileged
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
    template_file_id = proxmox_download_file.lxc_template_almalinux.id
    type             = "centos"
  }

  initialization {
    hostname = each.key

    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = "10.10.10.1"
      }
    }

    user_account {
      keys = [var.ssh_public_key]
    }
  }

  features {
    nesting = true
    mount   = ["nfs", "cifs"]
  }

  start_on_boot = true
}

# ============================================================
# Provisioning de AlmaLinux 9 ejecutado desde el Host Proxmox (pct exec)
# ============================================================
resource "null_resource" "lxc_provision_user" {
  for_each = var.lxc_containers

  triggers = {
    container_id = proxmox_virtual_environment_container.lxc_cluster[each.key].id
    ssh_key      = var.ssh_public_key
  }

  depends_on = [proxmox_virtual_environment_container.lxc_cluster]

  connection {
    type        = "ssh"
    host        = "10.10.10.1" # IP de la interfaz vmbr1 / Host Proxmox
    user        = "root"
    private_key = file("~/.ssh/id_systech_control")
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 3",
      
      # 1. Instalar y activar OpenSSH Server en AlmaLinux
      "pct exec ${each.value.vmid} -- bash -c 'dnf install -y openssh-server && systemctl enable --now sshd'",
      
      # 2. Configurar la red persistente vía NetworkManager
      "pct exec ${each.value.vmid} -- bash -c 'nmcli connection modify \"System eth0\" ipv4.addresses ${each.value.ip} ipv4.gateway 10.10.10.1 ipv4.dns \"1.1.1.1 8.8.8.8\" ipv4.method manual && nmcli connection up \"System eth0\"' || true",

      # 3. Crear el usuario ansible e inyectar la clave SSH
      "pct exec ${each.value.vmid} -- useradd -m -s /bin/bash ansible || true",
      "pct exec ${each.value.vmid} -- mkdir -p /home/ansible/.ssh",
      "pct exec ${each.value.vmid} -- bash -c \"echo '${var.ssh_public_key}' > /home/ansible/.ssh/authorized_keys\"",
      "pct exec ${each.value.vmid} -- chown -R ansible:ansible /home/ansible/.ssh",
      "pct exec ${each.value.vmid} -- chmod 700 /home/ansible/.ssh",
      "pct exec ${each.value.vmid} -- chmod 600 /home/ansible/.ssh/authorized_keys",
      "pct exec ${each.value.vmid} -- bash -c \"echo 'ansible ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible\"",
      "pct exec ${each.value.vmid} -- chmod 440 /etc/sudoers.d/ansible"
    ]
  }
}
