resource "null_resource" "wait_app_cloud_init" {
  count      = length(lxd_instance.app_vm)
  depends_on = [lxd_instance.app_vm]
  provisioner "local-exec" {
    command = "timeout 600 lxc exec ${lxd_instance.app_vm[count.index].name} -- bash -c 'cloud-init status --wait'"
  }
}

resource "null_resource" "wait_storage_cloud_init" {
  depends_on = [lxd_instance.storage_vm]
  provisioner "local-exec" {
    command = "timeout 600 lxc exec ${lxd_instance.storage_vm.name} -- bash -c 'cloud-init status --wait'"
  }
}

resource "null_resource" "wait_cliente_cloud_init" {
  depends_on = [lxd_instance.cliente_lxc]
  provisioner "local-exec" {
    command = "timeout 600 lxc exec ${lxd_instance.cliente_lxc.name} -- bash -c 'cloud-init status --wait'"
  }
}

# Generación de Inventario para Ansible
resource "local_file" "ansible_inventory" {
  depends_on = [
    null_resource.wait_app_cloud_init,
    null_resource.wait_storage_cloud_init,
    null_resource.wait_cliente_cloud_init,
    aws_route53_record.app_frontend
  ]
  
  content = <<-EOT
    [app_vms]
    %{ for i, vm in lxd_instance.app_vm ~}
    app-vm-${i + 1} ansible_host=${vm.ipv4_address}
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
