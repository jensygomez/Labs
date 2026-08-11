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
  ssh_pubkey       = trimspace(file(pathexpand("~/.ssh/id_lxd_fleet.pub")))
  fakecloud_endpoint = "http://10.45.223.1:4566"  # FakeCloud corre en el host
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

# --- APP SERVERS (server01, server02, server03) ---
resource "lxd_instance" "server" {
  count    = 3
  name     = format("server%02d", count.index + 1)
  image    = "almalinux9-cloud"
  type     = "container"
  profiles = [lxd_profile.fleet.name]

  config = {
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
        - path: /root/.aws/credentials
          owner: root:root
          permissions: '0600'
          content: |
            [default]
            aws_access_key_id = test
            aws_secret_access_key = test
        - path: /root/.aws/config
          owner: root:root
          permissions: '0600'
          content: |
            [default]
            region = us-east-1
      packages:
        - python3
        - openssh-server
        - tar
        - wget
        - curl
        - unzip
        - bind-utils
        - awscli
        - nginx
        - rsync
      runcmd:
        - ssh-keygen -A
        - systemctl enable --now sshd
        - systemctl enable --now nginx
        - mkdir -p /var/lib/node_exporter/textfile_collector
        - curl -sS -L https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz | tar -xz -C /tmp
        - cp /tmp/node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
        - useradd -rs /bin/false node_exporter || true
        - |
          cat > /etc/systemd/system/node_exporter.service << 'EOF'
          [Unit]
          Description=Node Exporter
          After=network.target
          [Service]
          Type=simple
          ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory=/var/lib/node_exporter/textfile_collector
          Restart=on-failure
          [Install]
          WantedBy=multi-user.target
          EOF
        - systemctl daemon-reload
        - systemctl enable --now node_exporter
    EOT
  }
}

# --- MONITORING (Prometheus) ---
resource "lxd_instance" "monitoring" {
  name     = "monitoring"
  image    = "almalinux9-cloud"
  type     = "container"
  profiles = [lxd_profile.fleet.name]

  config = {
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
      packages:
        - python3
        - openssh-server
        - tar
        - wget
        - curl
        - unzip
        - bind-utils
      runcmd:
        - ssh-keygen -A
        - systemctl enable --now sshd
    EOT
  }
}

# --- WAIT FOR CLOUD-INIT ---
resource "null_resource" "wait_server_cloud_init" {
  count      = length(lxd_instance.server)
  depends_on = [lxd_instance.server]
  provisioner "local-exec" {
    command = "timeout 600 lxc exec ${lxd_instance.server[count.index].name} -- bash -c 'cloud-init status --wait'"
  }
}

resource "null_resource" "wait_monitoring_cloud_init" {
  depends_on = [lxd_instance.monitoring]
  provisioner "local-exec" {
    command = "timeout 600 lxc exec ${lxd_instance.monitoring.name} -- bash -c 'cloud-init status --wait'"
  }
}

# --- PROVISIONERS ---
# FakeCloud ya está corriendo en el host, no necesitamos provisioner

resource "null_resource" "setup_monitoring" {
  depends_on = [null_resource.wait_monitoring_cloud_init]
  
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /opt/prometheus/rules",
      "wget -q https://github.com/prometheus/prometheus/releases/download/v2.51.0/prometheus-2.51.0.linux-amd64.tar.gz",
      "tar -xzf prometheus-2.51.0.linux-amd64.tar.gz",
      "mv prometheus-2.51.0.linux-amd64 /opt/prometheus",
      "cat > /opt/prometheus/prometheus.yml <<'EOF'\nglobal:\n  scrape_interval: 15s\nrule_files:\n  - /opt/prometheus/rules/*.yml\nscrape_configs:\n  - job_name: 'lxc'\n    static_configs:\n      - targets: ['${lxd_instance.server[0].ipv4_address}:9100', '${lxd_instance.server[1].ipv4_address}:9100', '${lxd_instance.server[2].ipv4_address}:9100']\n  - job_name: 'fakecloud'\n    static_configs:\n      - targets: ['10.45.223.1:4566']\nEOF",
      "cat > /etc/systemd/system/prometheus.service <<'EOF'\n[Unit]\nDescription=Prometheus\nAfter=network.target\n[Service]\nType=simple\nExecStart=/opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml --web.listen-address=0.0.0.0:9090\nRestart=on-failure\n[Install]\nWantedBy=multi-user.target\nEOF",
      "systemctl daemon-reload",
      "systemctl enable --now prometheus"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_lxd_fleet")
      host        = lxd_instance.monitoring.ipv4_address
    }
  }
}

# --- INVENTORY GENERATION ---
resource "local_file" "inventory" {
  depends_on = [
    null_resource.wait_server_cloud_init,
    null_resource.setup_monitoring
  ]
  
  content = templatefile("${path.module}/inventory.tpl", {
    servers = [
      for i, c in lxd_instance.server : {
        name = c.name
        ip   = c.ipv4_address
      }
    ]
    fakecloud_endpoint = local.fakecloud_endpoint
    monitoring_ip      = lxd_instance.monitoring.ipv4_address
  })
  filename = "${path.module}/inventory.ini"
}
