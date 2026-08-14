#!/usr/bin/env bash
set -euo pipefail

########################################
# Configuración general
########################################
# El script se autolocaliza: no depende de $HOME ni del nombre de usuario.
# BASH_SOURCE[0] = ruta desde donde se está ejecutando este archivo.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Como el script vive en scripts/, la raíz del proyecto es un nivel arriba.
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

BASE_IMG="${BASE_IMG:-/var/lib/libvirt/images/almalinux9-cloud-base.qcow2}"
LXC_IMAGE="${LXC_IMAGE:-ubuntu:24.04}"
SSH_PUBKEY_FILE="${SSH_PUBKEY_FILE:-$HOME/.ssh/id_lxd_fleet.pub}"
SSH_PRIVKEY_FILE="${SSH_PRIVKEY_FILE:-${SSH_PUBKEY_FILE%.pub}}"

MEMORY_MB=1536   # para VMs (puedes ajustar)
VCPUS=1

# VMs (nodos de aplicación y almacenamiento)
APP_VMS=(server01 server02 server03)
STORAGE_VMS=(storage01)
ALL_VMS=("${APP_VMS[@]}" "${STORAGE_VMS[@]}")

# Contenedores LXC (balanceadores y base de datos)
LB_CONTAINERS=(lb01 lb02)
DB_CONTAINERS=(db01)
ALL_CONTAINERS=("${LB_CONTAINERS[@]}" "${DB_CONTAINERS[@]}")

ALL_NODES=("${ALL_VMS[@]}" "${ALL_CONTAINERS[@]}")

INVENTORY_DIR="${INVENTORY_DIR:-${PROJECT_ROOT}/inventories/production}"
INVENTORY_FILE="${INVENTORY_DIR}/hosts.yml"

declare -A CURRENT_IPS=()

die() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ -f "$BASE_IMG" ]] || die "No existe la imagen base para KVM: $BASE_IMG"
[[ -f "$SSH_PUBKEY_FILE" ]] || die "No existe la clave pública SSH: $SSH_PUBKEY_FILE"
command -v lxc >/dev/null 2>&1 || die "El comando 'lxc' (Incus/LXD) no está instalado o en el PATH."

SSH_PUBKEY="$(cat "$SSH_PUBKEY_FILE")"

########################################
# Funciones: Libvirt / VMs
########################################
ensure_default_network() {
  # Ya no necesitamos la red default de libvirt, usamos lxdbr0.
  # Pero verificamos que lxdbr0 exista.
  if ! lxc network list --format csv | grep -q "^lxdbr0,"; then
    die "La red 'lxdbr0' de LXD no existe. Crea una con 'lxc network create lxdbr0'."
  fi
  echo "==> Red lxdbr0 disponible."
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

  local DISK_ARGS=("--disk" "path=${ROOT_DISK},format=qcow2")
  if [[ "$NAME" == "storage01" ]]; then
    for DISK_NAME in sdb sdc; do
      local EXTRA_DISK="/var/lib/libvirt/images/${NAME}-${DISK_NAME}.qcow2"
      if [[ ! -f "$EXTRA_DISK" ]]; then
        echo "==> Creando disco secundario para Storage: $EXTRA_DISK (10G)"
        sudo qemu-img create -f qcow2 "$EXTRA_DISK" 10G >/dev/null
      fi
      DISK_ARGS+=("--disk" "path=${EXTRA_DISK},format=qcow2")
    done
  fi

  # CAMBIO IMPORTANTE: usar bridge=lxdbr0 en lugar de network=default
  sudo virt-install \
    --name "$NAME" \
    --memory "$MEMORY_MB" \
    --vcpus "$VCPUS" \
    "${DISK_ARGS[@]}" \
    --os-variant almalinux9 \
    --network bridge=lxdbr0,model=virtio \
    --graphics none \
    --cloud-init "user-data=${CLOUDINIT_DIR}/user-data,meta-data=${CLOUDINIT_DIR}/meta-data" \
    --import \
    --noautoconsole
}

get_vm_ip() {
  local NAME="$1"
  local IP=""
  IP="$(sudo virsh domifaddr "$NAME" --source agent 2>/dev/null | awk '/ipv4/{print $4}' | cut -d/ -f1 | grep -v -E '^(127\.|169\.254\.)' | head -n1 || true)"
  if [[ -z "$IP" ]]; then
    IP="$(sudo virsh domifaddr "$NAME" 2>/dev/null | awk '/ipv4/{print $4}' | cut -d/ -f1 | grep -v -E '^(127\.|169\.254\.)' | head -n1 || true)"
  fi
  echo "$IP"
}

wait_vm_ip() {
  local NAME="$1"
  local IP=""
  echo "==> Esperando IP DHCP para VM $NAME..."
  for _ in $(seq 1 60); do
    IP="$(get_vm_ip "$NAME")"
    if [[ "$IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      CURRENT_IPS["$NAME"]="$IP"
      echo "==> [$NAME] IP detectada: $IP"
      return 0
    fi
    sleep 5
  done
  die "No se pudo detectar una IP DHCP para VM $NAME"
}

########################################
# Funciones: LXC / Contenedores
########################################
create_lxc() {
  local NAME="$1"

  if lxc info "$NAME" >/dev/null 2>&1; then
    if lxc info "$NAME" | grep -q "Status: STOPPED"; then
      echo "==> El contenedor '$NAME' existe pero está apagado; iniciándolo..."
      lxc start "$NAME"
    else
      echo "==> El contenedor LXC '$NAME' ya existe y está corriendo."
    fi
    return 0
  fi

  echo "==> Creando contenedor LXC: $NAME ($LXC_IMAGE)"
  lxc launch "$LXC_IMAGE" "$NAME"

  # Esperar a que el contenedor tenga red
  sleep 5

  # Instalar paquetes y configurar SSH
  echo "==> Configurando SSH y Python en el contenedor $NAME..."
  lxc exec "$NAME" -- apt-get update -y >/dev/null
  lxc exec "$NAME" -- apt-get install -y openssh-server python3 >/dev/null
  lxc exec "$NAME" -- mkdir -p /root/.ssh
  lxc exec "$NAME" -- chmod 700 /root/.ssh
  echo "$SSH_PUBKEY" | lxc exec "$NAME" -- tee /root/.ssh/authorized_keys >/dev/null
  lxc exec "$NAME" -- chmod 600 /root/.ssh/authorized_keys
  lxc exec "$NAME" -- sed -i 's/#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
  lxc exec "$NAME" -- systemctl enable --now ssh
}

wait_lxc_ip() {
  local NAME="$1"
  local IP=""
  echo "==> Esperando IP para contenedor LXC $NAME..."
  for _ in $(seq 1 30); do
    # MÉTODO CORREGIDO: usar 'lxc list' con salida CSV (estructurada),
    # en vez de parsear texto libre de 'lxc info' (formato frágil).
    # -c 4 = columna IPV4. Filtramos por nombre exacto con ^NAME$.
    IP="$(lxc list "^${NAME}\$" --format csv -c 4 2>/dev/null | cut -d' ' -f1 | head -n1 || true)"
    if [[ "$IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      CURRENT_IPS["$NAME"]="$IP"
      echo "==> [$NAME] IP detectada: $IP"
      return 0
    fi
    sleep 3
  done
  die "No se pudo detectar una IP para contenedor LXC $NAME"
}

########################################
# Espera de SSH (común)
########################################
wait_for_ssh() {
  local NAME="$1"
  local IP="${CURRENT_IPS[$NAME]}"

  echo "==> Verificando SSH en $NAME ($IP)..."
  for _ in $(seq 1 60); do
    if ssh -q \
      -o BatchMode=yes \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout=3 \
      -i "$SSH_PRIVKEY_FILE" \
      root@"$IP" true 2>/dev/null; then
      echo "==> [$NAME] SSH operativo."
      return 0
    fi
    sleep 3
  done
  echo "WARNING: SSH no respondió a tiempo en $NAME ($IP)." >&2
}

########################################
# Flujo Principal
########################################
echo "=================================================="
echo "   INICIANDO DESPLIEGUE DEL LABORATORIO HÍBRIDO"
echo "=================================================="

ensure_default_network

# 1. Crear VMs
for VM in "${ALL_VMS[@]}"; do
  create_vm "$VM"
done

# 2. Crear contenedores
for LXC in "${ALL_CONTAINERS[@]}"; do
  create_lxc "$LXC"
done

# 3. Obtener IPs
for VM in "${ALL_VMS[@]}"; do
  wait_vm_ip "$VM"
done

for LXC in "${ALL_CONTAINERS[@]}"; do
  wait_lxc_ip "$LXC"
done

# 4. Esperar SSH en todos los nodos
for NODE in "${ALL_NODES[@]}"; do
  wait_for_ssh "$NODE"
done

########################################
# Generar inventario Ansible
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
    lb_nodes:
      hosts:
EOF

for NODE in "${LB_CONTAINERS[@]}"; do
  cat >> "$INVENTORY_FILE" <<EOF
        ${NODE}:
          ansible_host: ${CURRENT_IPS[$NODE]}
EOF
done

cat >> "$INVENTORY_FILE" <<EOF

    ha_nodes:
      hosts:
EOF

for NODE in "${APP_VMS[@]}"; do
  cat >> "$INVENTORY_FILE" <<EOF
        ${NODE}:
          ansible_host: ${CURRENT_IPS[$NODE]}
EOF
done

cat >> "$INVENTORY_FILE" <<EOF

    storage_nodes:
      hosts:
EOF

for NODE in "${STORAGE_VMS[@]}"; do
  cat >> "$INVENTORY_FILE" <<EOF
        ${NODE}:
          ansible_host: ${CURRENT_IPS[$NODE]}
EOF
done

cat >> "$INVENTORY_FILE" <<EOF

    database_nodes:
      hosts:
EOF

for NODE in "${DB_CONTAINERS[@]}"; do
  cat >> "$INVENTORY_FILE" <<EOF
        ${NODE}:
          ansible_host: ${CURRENT_IPS[$NODE]}
EOF
done

echo ""
echo "=================================================="
echo "   LABORATORIO DESPLEGADO Y CONFIGURADO CON ÉXITO"
echo "=================================================="
echo ""
echo "==> Inventario Ansible generado ($INVENTORY_FILE):"
cat "$INVENTORY_FILE"
