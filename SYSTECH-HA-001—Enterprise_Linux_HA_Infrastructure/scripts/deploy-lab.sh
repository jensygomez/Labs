#!/usr/bin/env bash
set -euo pipefail

########################################
# Configuración general
########################################
BASE_IMG="${BASE_IMG:-/var/lib/libvirt/images/almalinux9-cloud-base.qcow2}"
SSH_PUBKEY_FILE="${SSH_PUBKEY_FILE:-$HOME/.ssh/id_lxd_fleet.pub}"
SSH_PRIVKEY_FILE="${SSH_PRIVKEY_FILE:-${SSH_PUBKEY_FILE%.pub}}"

MEMORY_MB=1024
VCPUS=1

APP_VMS=(server01 server02 server03)
STORAGE_VMS=(storage01 storage02)
ALL_VMS=("${APP_VMS[@]}" "${STORAGE_VMS[@]}")

INVENTORY_DIR="${INVENTORY_DIR:-$HOME/Labs/SYSTECH-HA-001—Enterprise_Linux_HA_Infrastructure/inventories/production}"
INVENTORY_FILE="${INVENTORY_DIR}/hosts.yml"

declare -A CURRENT_IPS=()

die() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ -f "$BASE_IMG" ]] || die "No existe la imagen base: $BASE_IMG"
[[ -f "$SSH_PUBKEY_FILE" ]] || die "No existe la clave pública SSH: $SSH_PUBKEY_FILE"

SSH_PUBKEY="$(cat "$SSH_PUBKEY_FILE")"

########################################
# Funciones auxiliares
########################################
ensure_default_network() {
  if ! sudo virsh net-info default >/dev/null 2>&1; then
    die "La red 'default' de libvirt no existe."
  fi

  if ! sudo virsh net-list --name | grep -qx "default"; then
    echo "==> Activando red default de libvirt..."
    sudo virsh net-start default
  else
    echo "==> Red 'default' de libvirt ya está activa."
  fi
}

create_vm() {
  local NAME="$1"
  local ROOT_DISK="/var/lib/libvirt/images/${NAME}-root.qcow2"
  local CLOUDINIT_DIR="/tmp/${NAME}-cloudinit"

  if sudo virsh dominfo "$NAME" >/dev/null 2>&1; then
    if sudo virsh domstate "$NAME" 2>/dev/null | grep -q "shut off"; then
      echo "==> La VM '$NAME' existe pero está apagada; iniciándola..."
      sudo virsh start "$NAME"
    else
      echo "==> La VM '$NAME' ya existe; se omite la creación."
    fi
    return 0
  fi

  echo "==> Creando VM: $NAME"
  sudo cp -f "$BASE_IMG" "$ROOT_DISK"

  mkdir -p "$CLOUDINIT_DIR"

  cat > "$CLOUDINIT_DIR/user-data" <<EOF
#cloud-config
disable_root: false
ssh_authorized_keys:
- ${SSH_PUBKEY}
packages:
- qemu-guest-agent
- python3
runcmd:
- systemctl enable --now qemu-guest-agent
EOF

  cat > "$CLOUDINIT_DIR/meta-data" <<EOF
instance-id: ${NAME}
local-hostname: ${NAME}
EOF

  sudo virt-install \
    --name "$NAME" \
    --memory "$MEMORY_MB" \
    --vcpus "$VCPUS" \
    --disk path="$ROOT_DISK",format=qcow2 \
    --os-variant almalinux9 \
    --network network=default,model=virtio \
    --graphics none \
    --cloud-init "user-data=${CLOUDINIT_DIR}/user-data,meta-data=${CLOUDINIT_DIR}/meta-data" \
    --import \
    --noautoconsole
}

get_vm_ip() {
  local NAME="$1"
  local IP=""

  # Intenta obtener la IP vía guest-agent excluyendo loopback (127.) y link-local (169.254.)
  IP="$(sudo virsh domifaddr "$NAME" --source agent 2>/dev/null | awk '/ipv4/{print $4}' | cut -d/ -f1 | grep -v -E '^(127\.|169\.254\.)' | head -n1 || true)"

  # Si no puede vía agent, intenta por lease DHCP de libvirt
  if [[ -z "$IP" ]]; then
    IP="$(sudo virsh domifaddr "$NAME" 2>/dev/null | awk '/ipv4/{print $4}' | cut -d/ -f1 | grep -v -E '^(127\.|169\.254\.)' | head -n1 || true)"
  fi

  echo "$IP"
}

wait_vm_ip() {
  local NAME="$1"
  local IP=""

  echo "==> Esperando IP DHCP para $NAME..."
  for _ in $(seq 1 60); do
    IP="$(get_vm_ip "$NAME")"

    if [[ "$IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      CURRENT_IPS["$NAME"]="$IP"
      echo "==> [$NAME] IP detectada: $IP"
      return 0
    fi

    sleep 5
  done

  die "No se pudo detectar una IP DHCP para $NAME"
}

wait_for_ssh() {
  local NAME="$1"
  local IP="${CURRENT_IPS[$NAME]}"

  echo "==> Esperando SSH para $NAME ($IP)..."
  for _ in $(seq 1 60); do
    if ssh -q \
      -o BatchMode=yes \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout=3 \
      -i "$SSH_PRIVKEY_FILE" \
      root@"$IP" true 2>/dev/null; then
      echo "==> [$NAME] SSH disponible."
      return 0
    fi

    sleep 5
  done

  echo "WARNING: SSH todavía no está disponible en $NAME. Puede que cloud-init siga iniciando." >&2
}

########################################
# Despliegue
########################################
ensure_default_network

for VM in "${ALL_VMS[@]}"; do
  create_vm "$VM"
done

for VM in "${ALL_VMS[@]}"; do
  wait_vm_ip "$VM"
done

for VM in "${ALL_VMS[@]}"; do
  wait_for_ssh "$VM"
done

########################################
# Generación de inventario Ansible
########################################
echo "==> Generando inventario Ansible: $INVENTORY_FILE"
mkdir -p "$INVENTORY_DIR"

cat > "$INVENTORY_FILE" <<EOF
all:
  vars:
    ansible_user: root
    ansible_ssh_private_key_file: ${SSH_PRIVKEY_FILE}
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

  children:
    ha_nodes:
      hosts:
EOF

for VM in "${APP_VMS[@]}"; do
  cat >> "$INVENTORY_FILE" <<EOF
        ${VM}:
          ansible_host: ${CURRENT_IPS[$VM]}
EOF
done

cat >> "$INVENTORY_FILE" <<EOF

    storage_nodes:
      hosts:
EOF

for VM in "${STORAGE_VMS[@]}"; do
  cat >> "$INVENTORY_FILE" <<EOF
        ${VM}:
          ansible_host: ${CURRENT_IPS[$VM]}
EOF
done

echo "==> Inventario generado:"
cat "$INVENTORY_FILE"

echo "=================================================="
echo "   LAB DESPLEGADO CORRECTAMENTE"
echo "=================================================="
