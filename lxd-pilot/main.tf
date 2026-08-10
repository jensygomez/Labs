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

# 1. Perfil Base LXD para los nodos
resource "lxd_profile" "fleet" {
  name = "fleet"
  config = {
    "limits.cpu"          = "1"
    "limits.memory"       = "512MB"
    "security.privileged" = "true"
  }
  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "lxdbr0"
    }
  }
}

# 2. Flota de Servidores (server01, server02, server03)
resource "lxd_container" "server" {
  count     = 3
  name      = format("server%02d", count.index + 1)
  image     = "images:almalinux/9"
  profiles  = [lxd_profile.fleet.name]

  config = {
    "user.network-config" = <<-EOT
      version: 2
      ethernets:
        eth0:
          addresses:
            - 10.45.223.${101 + count.index}/24
          gateway4: 10.45.223.1
          nameservers:
            addresses: [8.8.8.8, 1.1.1.1]
    EOT
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
        - systemctl enable --now sshd
        - sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
        - sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
        - systemctl restart sshd
    EOT
  }
}

# 3. Contenedor de Monitoreo (Prometheus)
resource "lxd_container" "monitoring" {
  name     = "monitoring"
  image    = "images:almalinux/9"
  profiles = [lxd_profile.fleet.name]

  config = {
    "user.network-config" = <<-EOT
      version: 2
      ethernets:
        eth0:
          addresses:
            - 10.45.223.105/24
          gateway4: 10.45.223.1
          nameservers:
            addresses: [8.8.8.8, 1.1.1.1]
    EOT
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
        - systemctl enable --now sshd
    EOT
  }
}

# 4. Inventario dinámico para Ansible
resource "local_file" "inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    servers = [
      { name = "server01", ip = "10.45.223.101" },
      { name = "server02", ip = "10.45.223.102" },
      { name = "server03", ip = "10.45.223.103" }
    ]
    monitoring_ip = "10.45.223.105"
    fakecloud_ip  = "127.0.0.1" # fakecloud corriendo nativamente en el host
  })
  filename = "${path.module}/inventory.ini"
}
