# Entorno técnico fijo

- **Provider**: libvirt (NUNCA sintaxis de VirtualBox en el Vagrantfile).
- **Nodos**:
  - `node01` — control/admin
  - `node02` — servidor
  - `node03` — cliente/destino
- **Usuario de trabajo**: `bob`, password `caleston123`, sudoer sin password.
- **Red privada**: `192.168.122.x`, `libvirt__network_name: "mgmt-net"`.
- **Bóveda de evidencia**: siempre en `node03`, bajo `/opt/ops-compliance/[id-lowercase]/`.
- **Ticket**: inyectado en node01 como `/home/vagrant/TICKET_[ID].txt`.
- **Verify script**: en node01 como `/tmp/verify-[id-lowercase].sh`.
- **Provision script**: en node01 como `/tmp/provision-[id-lowercase].sh`.
- **Discos extra**: si el incidente requiere más de un disco, agregarlo al array `extra_disks`
  del nodo correspondiente.
- **Limpieza de residuos**: usar `wipefs` y `umount` con `|| true` al inicio del provisioning,
  para borrar restos de incidentes anteriores en VMs reutilizadas.
- **Restricción de comandos**: no inventar comandos que no existan en Rocky Linux 9 / Ubuntu 22.04.
