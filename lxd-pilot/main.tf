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
      runcmd:
        - ssh-keygen -A
        - systemctl enable --now sshd
        - curl -sS -L https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz | tar -xz -C /tmp
        - cp /tmp/node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
        - useradd -rs /bin/false node_exporter || true
        - nohup /usr/local/bin/node_exporter > /var/log/node_exporter.log 2>&1 &
    EOT
  }
}

# --- FAKECLOUD (Local AWS Emulator) ---
resource "lxd_instance" "fakecloud" {
  name     = "fakecloud"
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
  count = length(lxd_instance.server)
  depends_on = [lxd_instance.server]
  provisioner "local-exec" {
    command = "timeout 600 lxc exec ${lxd_instance.server[count.index].name} -- bash -c 'cloud-init status --wait'"
  }
}

resource "null_resource" "wait_fakecloud_cloud_init" {
  depends_on = [lxd_instance.fakecloud]
  provisioner "local-exec" {
    command = "timeout 600 lxc exec ${lxd_instance.fakecloud.name} -- bash -c 'cloud-init status --wait'"
  }
}

resource "null_resource" "wait_monitoring_cloud_init" {
  depends_on = [lxd_instance.monitoring]
  provisioner "local-exec" {
    command = "timeout 600 lxc exec ${lxd_instance.monitoring.name} -- bash -c 'cloud-init status --wait'"
  }
}

# --- PROVISIONERS ---
resource "null_resource" "setup_fakecloud" {
  depends_on = [null_resource.wait_fakecloud_cloud_init]
  
  provisioner "remote-exec" {
    inline = [
      "export AWS_ACCESS_KEY_ID=test",
      "export AWS_SECRET_ACCESS_KEY=test",
      "export AWS_DEFAULT_REGION=us-east-1",
      "dnf install -y awscli",
      "curl -fsSL https://fakecloud.dev/install.sh | bash",
      "nohup fakecloud --port 4566 --host 0.0.0.0 > /var/log/fakecloud.log 2>&1 &",
      "sleep 10",
      "aws --endpoint-url http://localhost:4566 s3 mb s3://labs-logs || true",
      "aws --endpoint-url http://localhost:4566 iam create-role --role-name app-role --assume-role-policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}' || true",
      "aws --endpoint-url http://localhost:4566 iam attach-role-policy --role-name app-role --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess || true",
      "aws --endpoint-url http://localhost:4566 rds create-db-instance --db-instance-identifier mydb --db-instance-class db.t3.micro --engine postgres --master-username admin --master-user-password password123 --allocated-storage 20 || true"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_lxd_fleet")
      host        = lxd_instance.fakecloud.ipv4_address
    }
  }
}

resource "null_resource" "setup_monitoring" {
  depends_on = [null_resource.wait_monitoring_cloud_init]
  
  provisioner "remote-exec" {
    inline = [
      "wget -q https://github.com/prometheus/prometheus/releases/download/v2.51.0/prometheus-2.51.0.linux-amd64.tar.gz",
      "tar -xzf prometheus-2.51.0.linux-amd64.tar.gz",
      "mv prometheus-2.51.0.linux-amd64 /opt/prometheus",
      "cat > /opt/prometheus/prometheus.yml <<'EOF'\nglobal:\n  scrape_interval: 15s\nscrape_configs:\n  - job_name: 'lxc'\n    static_configs:\n      - targets: ['${lxd_instance.server[0].ipv4_address}:9100', '${lxd_instance.server[1].ipv4_address}:9100', '${lxd_instance.server[2].ipv4_address}:9100']\n  - job_name: 'fakecloud'\n    static_configs:\n      - targets: ['${lxd_instance.fakecloud.ipv4_address}:4566']\nEOF",
      "nohup /opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml --web.listen-address=0.0.0.0:9090 > /var/log/prometheus.log 2>&1 &"
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
    null_resource.setup_fakecloud,
    null_resource.setup_monitoring
  ]
  
  content = templatefile("${path.module}/inventory.tpl", {
    servers = [
      for i, c in lxd_instance.server : {
        name = c.name
        ip   = c.ipv4_address
      }
    ]
    fakecloud_ip  = lxd_instance.fakecloud.ipv4_address
    monitoring_ip = lxd_instance.monitoring.ipv4_address
  })
  filename = "${path.module}/inventory.ini"
}
