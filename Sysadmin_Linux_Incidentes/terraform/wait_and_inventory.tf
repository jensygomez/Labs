# ============================================================
# ESPERA A LXD-AGENT + CLOUD-INIT
# Las VMs necesitan que el lxd-agent arranque antes de "lxc exec"
# ============================================================

resource "null_resource" "wait_app_cloud_init" {
  count      = length(lxd_instance.app_vm)
  depends_on = [lxd_instance.app_vm]

  provisioner "local-exec" {
    command = <<-EOT
      VM="${lxd_instance.app_vm[count.index].name}"
      echo "==> [$VM] Esperando al lxd-agent..."
      AGENT_UP=false
      for i in $(seq 1 60); do
        if lxc exec "$VM" -- true >/dev/null 2>&1; then
          AGENT_UP=true
          break
        fi
        sleep 5
      done
      if [ "$AGENT_UP" != "true" ]; then
        echo "ERROR: [$VM] el lxd-agent no arrancó"
        exit 1
      fi
      echo "==> [$VM] Agent listo. Esperando cloud-init..."
      lxc exec "$VM" -- cloud-init status --wait
    EOT
  }
}

resource "null_resource" "wait_storage_cloud_init" {
  depends_on = [lxd_instance.storage_vm]

  provisioner "local-exec" {
    command = <<-EOT
      VM="storage-vm"
      echo "==> [$VM] Esperando al lxd-agent..."
      AGENT_UP=false
      for i in $(seq 1 60); do
        if lxc exec "$VM" -- true >/dev/null 2>&1; then
          AGENT_UP=true
          break
        fi
        sleep 5
      done
      if [ "$AGENT_UP" != "true" ]; then
        echo "ERROR: [$VM] el lxd-agent no arrancó"
        exit 1
      fi
      echo "==> [$VM] Agent listo. Esperando cloud-init..."
      lxc exec "$VM" -- cloud-init status --wait
    EOT
  }
}

resource "null_resource" "wait_cliente_cloud_init" {
  depends_on = [lxd_instance.cliente_lxc]

  provisioner "local-exec" {
    command = "lxc exec cliente-lxc -- cloud-init status --wait"
  }
}

# ============================================================
# GENERACIÓN DE INVENTARIO PARA ANSIBLE
# ============================================================
resource "local_file" "ansible_inventory" {
  depends_on = [
    null_resource.wait_app_cloud_init,
    null_resource.wait_storage_cloud_init,
    null_resource.wait_cliente_cloud_init,
  ]

  content = <<-EOT
    [app_vms]
    %{ for i, vm in lxd_instance.app_vm ~}
    ${vm.name} ansible_host=${vm.ipv4_address}
    %{ endfor ~}

    [storage_vms]
    storage-vm ansible_host=${lxd_instance.storage_vm.ipv4_address}

    [clientes]
    cliente-lxc ansible_host=${lxd_instance.cliente_lxc.ipv4_address}

    [fakecloud]
    localhost fakecloud_endpoint=http://${local.fakecloud_ip}:4566

    [all:vars]
    ansible_user=root
    ansible_ssh_private_key_file=~/.ssh/id_lxd_fleet
    ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
  EOT

  filename = "${path.module}/../ansible/inventory/hosts.ini"
}
