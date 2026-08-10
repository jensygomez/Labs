[app_fleet]
%{ for s in servers ~}
${s.name} ansible_host=${s.ip} ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_lxd_fleet
%{ endfor ~}

[monitoring]
monitoring_node ansible_host=${monitoring_ip} ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_lxd_fleet

[cloud]
localhost ansible_connection=local

[all:vars]
ansible_python_interpreter=/usr/bin/python3
