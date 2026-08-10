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

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "lxd" {}

locals {
  ssh_pubkey = trimspace(file(pathexpand("~/.ssh/id_lxd_fleet.pub")))

  user_data = templatefile("${path.module}/user-data.tftpl", {
    ssh_pubkey = local.ssh_pubkey
  })
}

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
  image    = "almalinux9-cloud"
  profiles = [lxd_profile.fleet.name]

  start_container  = true
  wait_for_network = true

  config = {
    "user.user-data" = local.user_data
  }
}

resource "lxd_container" "monitoring" {
  name     = "monitoring"
  image    = "almalinux9-cloud"
  profiles = [lxd_profile.fleet.name]

  start_container  = true
  wait_for_network = true

  config = {
    "user.user-data" = local.user_data
  }
}

resource "null_resource" "wait_server_cloud_init" {
  count = length(lxd_container.server)

  depends_on = [lxd_container.server]

  triggers = {
    instance_id = lxd_container.server[count.index].id
  }

  provisioner "local-exec" {
    command = "timeout 900 lxc exec ${lxd_container.server[count.index].name} -- bash -c 'cloud-init status --wait && systemctl is-active --quiet sshd'"
  }
}

resource "null_resource" "wait_monitoring_cloud_init" {
  depends_on = [lxd_container.monitoring]

  triggers = {
    instance_id = lxd_container.monitoring.id
  }

  provisioner "local-exec" {
    command = "timeout 900 lxc exec ${lxd_container.monitoring.name} -- bash -c 'cloud-init status --wait && systemctl is-active --quiet sshd'"
  }
}

resource "local_file" "inventory" {
  filename = "${path.module}/inventory.ini"

  content = templatefile("${path.module}/inventory.tpl", {
    servers = [
      for c in lxd_container.server : {
        name = c.name
        ip   = c.ip_address
      }
    ]
    monitoring_ip = lxd_container.monitoring.ip_address
  })

  depends_on = [
    null_resource.wait_server_cloud_init,
    null_resource.wait_monitoring_cloud_init
  ]
}
