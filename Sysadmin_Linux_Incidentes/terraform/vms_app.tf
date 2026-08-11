resource "lxd_volume" "app_lvm_disk" {
  count        = var.app_count
  name         = "app-lvm-${count.index + 1}"
  pool         = "default"
  content_type = "block"          # ← AGREGAR ESTA LÍNEA
  config = {
    size = "500MB"
  }
}

resource "lxd_volume" "app_data_disk" {
  count        = var.app_count
  name         = "app-data-${count.index + 1}"
  pool         = "default"
  content_type = "block"          # ← AGREGAR ESTA LÍNEA
  config = {
    size = "500MB"
  }
}

resource "lxd_instance" "app_vm" {
  count  = var.app_count
  name   = "app-vm-${count.index + 1}"
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
    name = "lvm-disk"
    type = "disk"
    properties = {
      pool   = "default"
      source = lxd_volume.app_lvm_disk[count.index].name
    }
  }

  device {
    name = "data-disk"
    type = "disk"
    properties = {
      pool   = "default"
      source = lxd_volume.app_data_disk[count.index].name
    }
  }
}
