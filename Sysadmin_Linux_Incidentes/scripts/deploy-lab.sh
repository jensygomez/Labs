#!/bin/bash
set -e

BASE_IMG="/var/lib/libvirt/images/almalinux9-cloud-base.qcow2"
CLOUDINIT_DIR="$HOME/Labs/Sysadmin_Linux_Incidentes/libvirt-cloudinit"
SSH_PUBKEY=$(cat ~/.ssh/id_lxd_fleet.pub)
LXC_IMAGE_ALIAS="almalinux9-cloud"
LXC_REMOTE_IMAGE="images:almalinux/9/cloud"

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

create_aws_vm() {
  local NAME=$1
  local RAM=$2
  local VCPUS=$3

  echo "==> Creando emulador AWS ($NAME)..."

  sudo cp "$BASE_IMG" "/var/lib/libvirt/images/${NAME}-root.qcow2"

  mkdir -p "/tmp/${NAME}-cloudinit"
  cat > "/tmp/${NAME}-cloudinit/user-data" <<EOF
#cloud-config
disable_root: false
ssh_authorized_keys:
  - ${SSH_PUBKEY}
packages:
  - yum-utils
  - device-mapper-persistent-data
  - lvm2
runcmd:
  - systemctl enable --now qemu-guest-agent
  - dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
  - dnf install -y docker-ce docker-ce-cli containerd.io
  - systemctl enable --now docker
  # Arrancar FakeCloud en el puerto 4566
  - docker run -d --name fakecloud -p 4566:4566 --restart always ghcr.io/fakecloud/fakecloud:latest
EOF
  cat > "/tmp/${NAME}-cloudinit/meta-data" <<EOF
instance-id: ${NAME}
local-hostname: ${NAME}
EOF

  sudo virt-install \
    --name "$NAME" \
    --memory "$RAM" \
    --vcpus "$VCPUS" \
    --disk path="/var/lib/libvirt/images/${NAME}-root.qcow2",format=qcow2 \
    --os-variant almalinux9 \
    --network network=default \
    --graphics none \
    --cloud-init "user-data=/tmp/${NAME}-cloudinit/user-data,meta-data=/tmp/${NAME}-cloudinit/meta-data" \
    --import \
    --noautoconsole
}

create_lxc_client() {
  local NAME=$1

  echo "==> Verificando imagen LXC '${LXC_IMAGE_ALIAS}'..."
  if ! lxc image info "${LXC_IMAGE_ALIAS}" &>/dev/null; then
    echo "--> Imagen no encontrada localmente. Descargando de ${LXC_REMOTE_IMAGE}..."
    lxc image copy "${LXC_REMOTE_IMAGE}" local: --alias "${LXC_IMAGE_ALIAS}"
  fi

  echo "==> Limpiando contenedor $NAME previo si existe..."
  if lxc info "$NAME" &>/dev/null; then
    lxc delete "$NAME" --force
  fi

  echo "==> Creando e iniciando contenedor LXC ($NAME)..."
  lxc launch "${LXC_IMAGE_ALIAS}" "$NAME" <<EOF
#cloud-config
disable_root: false
ssh_authorized_keys:
  - ${SSH_PUBKEY}
packages:
  - curl
  - bind-utils
  - iputils
  - nmap-ncat
EOF

  echo "==> Esperando asignación de IP para $NAME..."
  until lxc list "$NAME" -c 4 --format csv | grep -qE '([0-9]{1,3}\.){3}[0-9]{1,3}'; do
    sleep 1
  done
  echo "==> [$NAME] Listo e inicializado."
}

# 1. Despliegue de VMs de la topología (KVM / libvirt)
create_vm "app-vm-1" "lvm" "2G"
create_vm "app-vm-2" "lvm" "2G"
create_vm "app-vm-3" "lvm" "2G"
create_vm "storage-vm" "nfs" "2G"

# 2. VM para emulador local de AWS (Docker/FakeCloud)
create_aws_vm "aws-local-vm" "2048" "2"

# 3. Contenedor LXC Cliente
create_lxc_client "cliente-lxc"

# 4. Verificación de Guest-Agents en KVM
echo "==> Esperando qemu-guest-agents en las VMs..."
ALL_VMS="app-vm-1 app-vm-2 app-vm-3 storage-vm aws-local-vm"
for VM in $ALL_VMS; do
  for i in $(seq 1 40); do
    if sudo virsh qemu-agent-command "$VM" '{"execute":"guest-ping"}' >/dev/null 2>&1; then
      echo "==> [$VM] Agent listo."
      break
    fi
    sleep 5
  done
done
# 5. Generación del inventario de Ansible
echo "==> Generando inventario Ansible..."
mkdir -p "$HOME/Labs/Sysadmin_Linux_Incidentes/ansible/inventory"
INV="$HOME/Labs/Sysadmin_Linux_Incidentes/ansible/inventory/hosts.ini"

# Mapeo de IPs Estáticas definitivas
declare -A STATIC_IPS=(
  ["app-vm-1"]="192.168.122.11"
  ["app-vm-2"]="192.168.122.12"
  ["app-vm-3"]="192.168.122.13"
  ["storage-vm"]="192.168.122.10"
  ["aws-local-vm"]="192.168.122.50"
)

echo "[app_vms]" > "$INV"
for VM in app-vm-1 app-vm-2 app-vm-3; do
  IP=$(sudo virsh domifaddr "$VM" | awk '/ipv4/{print $4}' | cut -d/ -f1)
  echo "${VM} ansible_host=${IP} static_ip=${STATIC_IPS[$VM]}" >> "$INV"
done

echo "" >> "$INV"
echo "[storage_vms]" >> "$INV"
IP=$(sudo virsh domifaddr storage-vm | awk '/ipv4/{print $4}' | cut -d/ -f1)
echo "storage-vm ansible_host=${IP} static_ip=${STATIC_IPS['storage-vm']}" >> "$INV"

echo "" >> "$INV"
echo "[aws_cloud_vms]" >> "$INV"
AWS_IP=$(sudo virsh domifaddr aws-local-vm | awk '/ipv4/{print $4}' | cut -d/ -f1)
echo "aws-local-vm ansible_host=${AWS_IP} static_ip=${STATIC_IPS['aws-local-vm']} aws_endpoint=http://${AWS_IP}:4566" >> "$INV"

echo "" >> "$INV"
echo "[client_nodes]" >> "$INV"
CLIENT_IP=$(lxc list cliente-lxc -c 4 --format csv | awk '{print $1}')
echo "cliente-lxc ansible_host=${CLIENT_IP}" >> "$INV"

echo "" >> "$INV"
echo "[all:vars]" >> "$INV"
echo "ansible_user=root" >> "$INV"
echo "ansible_ssh_private_key_file=~/.ssh/id_lxd_fleet" >> "$INV"
echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'" >> "$INV"
