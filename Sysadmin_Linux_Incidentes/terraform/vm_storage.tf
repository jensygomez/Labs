resource "lxd_volume" "storage_nfs_disk" {
  name         = "storage-nfs-disk"
  pool         = "default"
  content_type = "block"          # ← AGREGAR ESTA LÍNEA
  config = {
    size = "1GB"
  }
}

resource "lxd_instance" "storage_vm" {
  name   = "storage-vm"
  image  = local.vm_image
  type   = "virtual-machine"

  config = {
    "limits.cpu"    = "1"
    "limits.memory" = "1GB"
    "user.user-data" = <<-EOT
      #cloud-config
      disable_root: false
      ssh_authorized_keys:
        - ${local.ssh_pubkey}
      write_files:
        - path: /etc/ssh/sshd_config.d/00-lxd-root.conf
          content: |
            PermitRootLogin yes
            PasswordAuthentication no
      runcmd:
        - ssh-keygen -A
        - systemctl enable --now sshd
    EOT
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "lxdbr0"
    }
  }

  device {
    name = "nfs-disk"
    type = "disk"
    properties = {
      pool   = "default"
      source = lxd_volume.storage_nfs_disk.name
    }
  }
}
