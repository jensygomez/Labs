# Imagen cloud-init de AlmaLinux 9 (misma fuente que SYSTECH-HA-001)
resource "proxmox_download_file" "almalinux_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.target_node
  url          = "https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
  file_name    = "almalinux-9-cloudinit.iso"
}

# Snippet de Cloud-Init (uno por VM)
resource "proxmox_virtual_environment_file" "cloud_user_config" {
  for_each     = var.cluster_nodes
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node
  source_raw {
    data      = <<-EOF
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

# Snippet de Meta-Data (fix del bug "hostname: localhost")
resource "proxmox_virtual_environment_file" "cloud_meta_config" {
  for_each     = var.cluster_nodes
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node
  source_raw {
    data      = <<-EOF
    instance-id: ${each.key}
    local-hostname: ${each.key}
    EOF
    file_name = "cloud-meta-config-${each.key}.yml"
  }
}

# Cluster de VMs Kubernetes (master + workers)
resource "proxmox_virtual_environment_vm" "k8s_cluster" {
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

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_download_file.almalinux_cloud_image.id
    interface    = "scsi0"
    size         = each.value.disk_size
  }

  # Discos extra opcionales (ej. para storage de PVs más adelante)
  dynamic "disk" {
    for_each = [for idx, size in each.value.extra_disks : { index = idx + 1, size = size }]
    content {
      datastore_id = "local-lvm"
      interface    = "scsi${disk.value.index}"
      size         = disk.value.size
      file_format  = "raw"
    }
  }

  network_device {
    bridge = "vmbr1"
    model  = "virtio"
  }

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

# ============================================================
# Inventario de Ansible — preparado pero comentado hasta que
# trabajemos esa parte (falta inventory.tmpl)
# ============================================================
# resource "local_file" "ansible_inventory" {
#   content = templatefile("${path.module}/inventory.tmpl", {
#     nodes = {
#       for k, vm in proxmox_virtual_environment_vm.k8s_cluster : k => {
#         name = k
#         ip   = var.cluster_nodes[k].ip
#         role = var.cluster_nodes[k].role
#       }
#     }
#     role_group_map = {
#       master = "k8s_control_plane"
#       worker = "k8s_workers"
#     }
#   })
#   filename = "${path.module}/../ansible/inventories/production/hosts.yml"
# }
