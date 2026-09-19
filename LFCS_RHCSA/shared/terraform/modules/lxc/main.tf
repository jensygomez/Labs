terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.50.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }
  }
}


resource "proxmox_download_file" "lxc_template" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = var.target_node
  url          = "http://download.proxmox.com/images/system/almalinux-9-default_20240911_amd64.tar.xz"
  file_name    = "almalinux-9-default_20240911_amd64.tar.xz"
  overwrite    = true
}

resource "proxmox_virtual_environment_container" "lxc_cluster" {
  for_each     = var.containers
  node_name    = var.target_node
  vm_id        = each.value.vmid
  unprivileged = !each.value.privileged
  started      = true

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = "local-lvm"
    size         = each.value.disk_size
  }
  
  network_interface {
    name   = "eth0"
    bridge = "vmbr1"
  }
  
  operating_system {
    template_file_id = proxmox_download_file.lxc_template.id
    type             = "centos"
  }

  initialization {
    hostname = each.key
    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = "10.10.10.1"
      }
    }
    user_account {
      keys = [var.ssh_public_key]
    }
  }

  features {
    nesting = true
    mount   = ["nfs", "cifs"]
  }
  
  start_on_boot = true
}

resource "null_resource" "lxc_provision_user" {
  for_each   = var.containers
  triggers   = { container_id = proxmox_virtual_environment_container.lxc_cluster[each.key].id }
  depends_on = [proxmox_virtual_environment_container.lxc_cluster]

  connection {
    type        = "ssh"
    host        = var.proxmox_host_ip
    user        = "root"
    private_key = var.ssh_private_key
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 3",
      "pct exec ${each.value.vmid} -- bash -c 'dnf install -y openssh-server && systemctl enable --now sshd'",
      "pct exec ${each.value.vmid} -- bash -c 'nmcli connection modify \"System eth0\" ipv4.addresses ${each.value.ip} ipv4.gateway 10.10.10.1 ipv4.dns \"1.1.1.1 8.8.8.8\" ipv4.method manual && nmcli connection up \"System eth0\"' || true",
      "pct exec ${each.value.vmid} -- useradd -m -s /bin/bash ansible || true",
      "pct exec ${each.value.vmid} -- mkdir -p /home/ansible/.ssh",
      "pct exec ${each.value.vmid} -- bash -c \"echo '${var.ssh_public_key}' > /home/ansible/.ssh/authorized_keys\"",
      "pct exec ${each.value.vmid} -- chown -R ansible:ansible /home/ansible/.ssh",
      "pct exec ${each.value.vmid} -- chmod 700 /home/ansible/.ssh && chmod 600 /home/ansible/.ssh/authorized_keys",
      "pct exec ${each.value.vmid} -- bash -c \"echo 'ansible ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible\"",
      "pct exec ${each.value.vmid} -- chmod 440 /etc/sudoers.d/ansible"
    ]
  }
}
