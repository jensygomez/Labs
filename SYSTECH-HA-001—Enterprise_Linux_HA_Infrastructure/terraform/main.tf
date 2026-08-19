# Descargar la imagen genérica de AlmaLinux 9 Cloud-Init directamente a Proxmox
resource "proxmox_download_file" "almalinux_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.target_node
  url          = "https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
  file_name    = "almalinux-9-cloudinit.iso" # ← Corregido: .qcow2 → .iso
}

# Snippet de Cloud-Init (uno por VM, con hostname correcto)
resource "proxmox_virtual_environment_file" "cloud_user_config" {
  for_each     = var.cluster_nodes
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: ${each.key}
    preserve_hostname: false
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
    file_name = "cloud-user-config-${each.key}.yml"
  }
}

# Snippet de Meta-Data (uno por VM) — FIX del bug "hostname: localhost"
resource "proxmox_virtual_environment_file" "cloud_meta_config" {
  for_each     = var.cluster_nodes
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node

  source_raw {
    data = <<-EOF
    instance-id: ${each.key}
    local-hostname: ${each.key}
    EOF
    file_name = "cloud-meta-config-${each.key}.yml"
  }
}

# Recurso para crear el Cluster de 3 VMs AlmaLinux
resource "proxmox_virtual_environment_vm" "almalinux_cluster" {
  for_each = var.cluster_nodes

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
    file_id      = proxmox_download_file.almalinux_cloud_image.id
    interface    = "scsi0"
    size         = 20
  }

  # Discos adicionales dinámicos para LVM / Storage (scsi1, scsi2, scsi3)
  dynamic "disk" {
    for_each = [for idx, size in each.value.extra_disks : { index = idx + 1, size = size }]
    content {
      datastore_id = "local-lvm"
      interface    = "scsi${disk.value.index}"
      size         = disk.value.size
      file_format  = "raw"
    }
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
    user_data_file_id = proxmox_virtual_environment_file.cloud_user_config[each.key].id
    meta_data_file_id = proxmox_virtual_environment_file.cloud_meta_config[each.key].id
  }
} 

# Generación automática del inventario de Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    vms = {
      for k, vm in proxmox_virtual_environment_vm.almalinux_cluster : k => {
        name = k
        ip   = var.cluster_nodes[k].ip
      }
    }
    lxcs = {
      for k, lxc in proxmox_virtual_environment_container.lxc_cluster : k => {
        name = k
        ip   = var.lxc_containers[k].ip
      }
    }
  })
  filename = "${path.module}/../ansible/inventories/production/hosts.yml"
}
