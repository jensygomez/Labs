resource "lxd_instance" "cliente_lxc" {
  name   = "cliente-lxc"
  image  = local.lxc_image
  type   = "container"
  
  config = {
    "limits.cpu"    = "1"
    "limits.memory" = "256MB"
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
      network = "lxdbr0"  # Referencia directa por nombre
    }
  }
}
