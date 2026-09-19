resource "proxmox_download_file" "almalinux_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.target_node
  url          = "https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
  file_name    = "almalinux-9-cloudinit.iso"
}

resource "proxmox_virtual_environment_file" "cloud_user_config" {
  for_each     = var.vms
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node
  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: ${each.key}
    users:
      - name: ansible
        groups: wheel
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - ${var.ssh_public_key}
    package_update: true
    packages: [qemu-guest-agent, curl, python3]
    runcmd:
      - systemctl enable --now qemu-guest-agent
    EOF
    file_name = "cloud-user-config-${each.key}.yml"
  }
}

resource "proxmox_virtual_environment_file" "cloud_meta_config" {
  for_each     = var.vms
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node
  source_raw {
    data      = "instance-id: ${each.key}\nlocal-hostname: ${each.key}"
    file_name = "cloud-meta-config-${each.key}.yml"
  }
}

resource "proxmox_virtual_environment_vm" "vm_cluster" {
  for_each  = var.vms
  name      = each.key
  node_name = var.target_node
  vm_id     = each.value.vmid

  cpu    { cores = each.value.cores; type = "host" }
  memory { dedicated = each.value.memory }
  agent  { enabled = true }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_download_file.almalinux_cloud_image.id
    interface    = "scsi0"
    size         = each.value.disk_size
  }

  dynamic "disk" {
    for_each = [for idx, size in each.value.extra_disks : { index = idx + 1, size = size }]
    content {
      datastore_id = "local-lvm"
      interface    = "scsi${disk.value.index}"
      size         = disk.value.size
      file_format  = "raw"
    }
  }

  network_device { bridge = "vmbr1"; model = "virtio" }

  initialization {
    ip_config { ipv4 { address = each.value.ip; gateway = "10.10.10.1" } }
    user_data_file_id = proxmox_virtual_environment_file.cloud_user_config[each.key].id
    meta_data_file_id = proxmox_virtual_environment_file.cloud_meta_config[each.key].id
  }
}
