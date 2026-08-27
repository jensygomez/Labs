# incus_instances.tf

# ==============================================================================
# 1. CLUSTER DE CONTENEDORES LXC (Ubuntu 24.04)
# ==============================================================================
resource "incus_instance" "lxc_cluster" {
  for_each = var.lxc_containers

  name      = each.key
  image     = "images:ubuntu/24.04"
  type      = "container"
  profiles  = ["default"]
  running   = true

  config = {
    "limits.cpu"    = each.value.cores
    "limits.memory" = "${each.value.memory}MiB"
    
    # Cloud-Init: Configuración de red + usuarios + paquetes
    "user.user-data" = <<-EOF
      #cloud-config
      hostname: ${each.key}
      preserve_hostname: false
      
      # Configuración de red estática para systemd-networkd
      network:
        version: 2
        ethernets:
          eth0:
            dhcp4: false
            addresses:
              - ${each.value.ip}
            routes:
              - to: default
                via: 10.10.10.1
            nameservers:
              addresses: [10.10.10.1]
      
      users:
        - name: ansible
          groups: sudo
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
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network        = "incusbr0"
      "ipv4.address" = split("/", each.value.ip)[0]
    }
  }
}

# ==============================================================================
# 2. CLUSTER DE MÁQUINAS VIRTUALES (AlmaLinux 9)
# ==============================================================================
resource "incus_instance" "vm_cluster" {
  for_each = var.cluster_nodes

  name      = each.key
  image     = "images:almalinux/9/cloud"
  type      = "virtual-machine"
  profiles  = ["default"]
  running   = true

  config = {
    "limits.cpu"    = each.value.cores
    "limits.memory" = "${each.value.memory}MiB"
    
    # Cloud-Init: Configuración de red + usuarios + paquetes
    "user.user-data" = <<-EOF
      #cloud-config
      hostname: ${each.key}
      preserve_hostname: false
      
      # Configuración de red estática para NetworkManager
      network:
        version: 2
        ethernets:
          eth0:
            dhcp4: false
            addresses:
              - ${each.value.ip}
            routes:
              - to: default
                via: 10.10.10.1
            nameservers:
              addresses: [10.10.10.1]
      
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
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network        = "incusbr0"
      "ipv4.address" = split("/", each.value.ip)[0]
    }
  }

  dynamic "device" {
    for_each = { for idx, size in each.value.extra_disks : "disk${idx + 1}" => size }
    content {
      name = device.key
      type = "disk"
      properties = {
        pool = "default"
        size = "${device.value}GiB"
        path = "/mnt/${device.key}"
      }
    }
  }
}
