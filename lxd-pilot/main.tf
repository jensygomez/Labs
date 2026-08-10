terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "~> 1.10"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "lxd" {}

resource "lxd_profile" "fleet" {
  name = "fleet"
  config = {
    "limits.cpu"          = "1"
    "limits.memory"       = "512MB"
    "security.privileged" = "true"
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = "default"
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "lxdbr0"
    }
  }
}

resource "lxd_container" "server" {
  count    = 3
  name     = format("server%02d", count.index + 1)
  image    = "almalinux9"
  profiles = [lxd_profile.fleet.name]

  config = {
    "user.user-data" = <<-EOT
      #cloud-config
      ssh_authorized_keys:
        - ${file("~/.ssh/id_lxd_fleet.pub")}
      packages:
        - python3
        - openssh-server
        - e2fsprogs
        - tar
        - wget
      runcmd:
        - ssh-keygen -A
        - systemctl enable --now sshd
        - sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
        - sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
        - systemctl restart sshd
    EOT
  }
}

resource "lxd_container" "monitoring" {
  name     = "monitoring"
  image    = "almalinux9"
  profiles = [lxd_profile.fleet.name]

  config = {
    "user.user-data" = <<-EOT
      #cloud-config
      ssh_authorized_keys:
        - ${file("~/.ssh/id_lxd_fleet.pub")}
      packages:
        - python3
        - openssh-server
        - wget
        - tar
      runcmd:
        - ssh-keygen -A
        - systemctl enable --now sshd
    EOT
  }
}

resource "local_file" "inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    servers = [
      for c in lxd_container.server : {
        name = c.name
        ip   = c.ip_address
      }
    ]
    monitoring_ip = lxd_container.monitoring.ip_address
  })
  filename = "${path.module}/inventory.ini"
}
