[app_fleet]
%{ for s in servers ~}
${s.name} ansible_host=${s.ip} ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_lxd_fleet
%{ endfor ~}

[cloud]
fakecloud ansible_host=${fakecloud_ip} ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_lxd_fleet
monitoring_node ansible_host=${monitoring_ip} ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_lxd_fleet

[local]
localhost ansible_connection=local

[all:vars]
ansible_python_interpreter=/usr/bin/python3
