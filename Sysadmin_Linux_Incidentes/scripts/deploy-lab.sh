#!/bin/bash
set -e

BASE_IMG="/var/lib/libvirt/images/almalinux9-cloud-base.qcow2"
CLOUDINIT_DIR="$HOME/Labs/Sysadmin_Linux_Incidentes/libvirt-cloudinit"
SSH_PUBKEY=$(cat ~/.ssh/id_lxd_fleet.pub)

create_vm() {
  local NAME=$1
  local EXTRA_DISK_LABEL=$2
  local EXTRA_DISK_SIZE=$3

  echo "==> Creando $NAME..."

  sudo cp "$BASE_IMG" "/var/lib/libvirt/images/${NAME}-root.qcow2"
  sudo qemu-img create -f qcow2 "/var/lib/libvirt/images/${NAME}-${EXTRA_DISK_LABEL}.qcow2" "$EXTRA_DISK_SIZE"

  mkdir -p "/tmp/${NAME}-cloudinit"
  cat > "/tmp/${NAME}-cloudinit/user-data" <<EOF
#cloud-config
disable_root: false
ssh_authorized_keys:
  - ${SSH_PUBKEY}
runcmd:
  - systemctl enable --now qemu-guest-agent
EOF
  cat > "/tmp/${NAME}-cloudinit/meta-data" <<EOF
instance-id: ${NAME}
local-hostname: ${NAME}
EOF

  sudo virt-install \
    --name "$NAME" \
    --memory 1024 \
    --vcpus 1 \
    --disk path="/var/lib/libvirt/images/${NAME}-root.qcow2",format=qcow2 \
    --disk path="/var/lib/libvirt/images/${NAME}-${EXTRA_DISK_LABEL}.qcow2",format=qcow2 \
    --os-variant almalinux9 \
    --network network=default \
    --graphics none \
    --cloud-init "user-data=/tmp/${NAME}-cloudinit/user-data,meta-data=/tmp/${NAME}-cloudinit/meta-data" \
    --import \
    --noautoconsole
}

create_vm "app-vm-1" "lvm" "2G"
create_vm "app-vm-2" "lvm" "2G"
create_vm "app-vm-3" "lvm" "2G"
create_vm "storage-vm" "nfs" "2G"

echo "==> Esperando guest-agents..."
for VM in app-vm-1 app-vm-2 app-vm-3 storage-vm; do
  for i in $(seq 1 30); do
    if sudo virsh qemu-agent-command "$VM" '{"execute":"guest-ping"}' >/dev/null 2>&1; then
      echo "==> [$VM] Agent listo."
      break
    fi
    sleep 5
  done
done

echo "==> Generando inventario Ansible..."
mkdir -p "$HOME/Labs/Sysadmin_Linux_Incidentes/ansible/inventory"
INV="$HOME/Labs/Sysadmin_Linux_Incidentes/ansible/inventory/hosts.ini"

echo "[app_vms]" > "$INV"
for VM in app-vm-1 app-vm-2 app-vm-3; do
  IP=$(sudo virsh domifaddr "$VM" | awk '/ipv4/{print $4}' | cut -d/ -f1)
  echo "${VM} ansible_host=${IP}" >> "$INV"
done

echo "" >> "$INV"
echo "[storage_vms]" >> "$INV"
IP=$(sudo virsh domifaddr storage-vm | awk '/ipv4/{print $4}' | cut -d/ -f1)
echo "storage-vm ansible_host=${IP}" >> "$INV"

echo "" >> "$INV"
echo "[all:vars]" >> "$INV"
echo "ansible_user=root" >> "$INV"
echo "ansible_ssh_private_key_file=~/.ssh/id_lxd_fleet" >> "$INV"
echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'" >> "$INV"

echo "==> Listo. Inventario en $INV"
cat "$INV"
