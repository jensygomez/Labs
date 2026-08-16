# Descargar la imagen genérica de AlmaLinux 9 Cloud-Init directamente a Proxmox
resource "proxmox_download_file" "almalinux_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.target_node
  url          = "https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
  file_name    = "almalinux-9-cloudinit.qcow2"
}

# Snippet de Cloud-Init para personalización adicional
resource "proxmox_virtual_environment_file" "cloud_user_config" {
  content_type  = "snippets"
  datastore_id  = "local"
  node_name     = var.target_node

  source_raw {
    data = <<-EOF
    #cloud-config
    users:
      - name: ansible
        groups: wheel
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - ${var.ssh_public_key}
    package_update: true
    packages:
      - qemu-guest-agent
      - curl
      - python3
    runcmd:
      - systemctl enable --now qemu-guest-agent
    EOF
    file_name = "cloud-user-config.yml"
  }
}

# Recurso para crear el Cluster de 3 VMs AlmaLinux
resource "proxmox_virtual_environment_vm" "almalinux_cluster" {
  for_each  = var.cluster_nodes

  name      = each.key
  node_name = var.target_node
  vm_id     = each.value.vmid

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  agent {
    enabled = true
  }

  # Disco principal del Sistema Operativo
  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_download_file.almalinux_cloud_image.id # ✅ Referencia corregida
    interface    = "scsi0"
    size         = 20
  }

  # Configuración de Red vinculada al bridge vmbr1 (Red del Laboratorio)
  network_device {
    bridge = "vmbr1"
    model  = "virtio"
  }

  # Inyección de Cloud-init
  initialization {
    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = "10.10.10.1"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_user_config.id
  }
}
