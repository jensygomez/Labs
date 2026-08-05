#!/usr/bin/env bash
# make-node.sh
#
# Levanta UNA VM a partir de la imagen dorada, usando un overlay
# copy-on-write (no toca la imagen dorada) + cloud-init para la
# configuracion inicial (hostname, IP estatica, TU clave SSH via el
# mecanismo NATIVO de cloud-init -- no el truco manual de appendear
# a authorized_keys que veniamos usando con Vagrant).
#
# Uso:
#   bash make-node.sh <nombre> <ip> [paquetes-extra separados por coma]
#
# Ejemplo:
#   bash make-node.sh node01 192.168.122.11
#   bash make-node.sh node04 192.168.122.14 nfs-utils

set -o errexit
set -o pipefail

NODE_NAME="$1"
NODE_IP="$2"
EXTRA_PACKAGES="${3:-}"

if [ -z "$NODE_NAME" ] || [ -z "$NODE_IP" ]; then
  echo "Uso: bash make-node.sh <nombre> <ip> [paquetes-extra]"
  exit 1
fi

IMG_DIR="$HOME/vm-images"
GOLDEN_IMG="$IMG_DIR/golden-almalinux9.qcow2"
NODE_DIR="$IMG_DIR/$NODE_NAME"
NODE_DISK="$NODE_DIR/disk.qcow2"
SEED_ISO="$NODE_DIR/seed.iso"
NETWORK_NAME="mgmt-net"
GATEWAY_IP="192.168.122.1"
LAB_PUBKEY=$(cat "$HOME/.ssh/id_ed25519_labs.pub")

mkdir -p "$NODE_DIR"

# --- 1. Overlay copy-on-write, la dorada nunca se toca ---
echo "==> [$NODE_NAME] Creando disco overlay..."
qemu-img create -f qcow2 -F qcow2 -b "$GOLDEN_IMG" "$NODE_DISK" 20G

# --- 2. cloud-init: user-data (que instalar, que usuario, que clave) ---

# 🧰 EL BOTIQUÍN DE DIAGNÓSTICO (Cubre el 95% de los 50 incidentes)
BASE_PACKAGES=(
    "qemu-guest-agent"
    # Redes y Firewalls
    "nmap-ncat" "tcpdump" "bind-utils" "iproute" "firewalld" "python3-firewall" "nfs-utils"
    # Storage y Sistema
    "lsof" "strace" "sysstat" "lvm2" "e2fsprogs" "xfsprogs"
    # Seguridad y Logs
    "policycoreutils-python-utils" "setools-console" "audit"
    # Comodidad Básica (Para que no sufras en la terminal)
    "vim-enhanced" "tmux" "htop" "git" "bash-completion"
)

# Unimos los paquetes base con los extra (si los pasaste como argumento)
PACKAGE_LIST="${BASE_PACKAGES[*]}"
if [ -n "$EXTRA_PACKAGES" ]; then
    PACKAGE_LIST="$PACKAGE_LIST ${EXTRA_PACKAGES}"
fi

# Convertimos la lista separada por espacios a formato YAML para cloud-init
PACKAGE_LIST_YAML=$(echo "$PACKAGE_LIST" | tr ' ' '\n' | sed 's/^/  - /')

cat > "$NODE_DIR/user-data" <<EOF
#cloud-config
hostname: ${NODE_NAME}
manage_etc_hosts: true

# Usuario corporativo estándar (sin 'vagrant', sin 'jensyg' para no confundir)
users:
- name: labadmin
  sudo: ALL=(ALL) NOPASSWD:ALL
  groups: wheel
  shell: /bin/bash
  ssh_authorized_keys:
  - ${LAB_PUBKEY}

package_update: false
packages:
${PACKAGE_LIST_YAML}

runcmd:
  - systemctl enable --now qemu-guest-agent
  - systemctl enable --now firewalld
EOF

# --- 3. cloud-init: network-config (IP estatica, sin DHCP) ---
cat > "$NODE_DIR/network-config" <<EOF
version: 2
ethernets:
  eth0:
    addresses:
      - ${NODE_IP}/24
    gateway4: ${GATEWAY_IP}
    nameservers:
      addresses: [8.8.8.8]
EOF

cat > "$NODE_DIR/meta-data" <<EOF
instance-id: ${NODE_NAME}
local-hostname: ${NODE_NAME}
EOF

# --- 4. Empaquetar todo en un ISO "NoCloud" que cloud-init lee al boot ---
echo "==> [$NODE_NAME] Generando seed ISO de cloud-init..."
genisoimage -output "$SEED_ISO" -volid cidata -joliet -rock \
  "$NODE_DIR/user-data" "$NODE_DIR/meta-data" "$NODE_DIR/network-config" \
  >/dev/null 2>&1

# --- 5. Definir y arrancar el dominio libvirt ---
# IMPORTANTE: sin --connect explicito, virt-install puede conectarse a
# qemu:///session (una instancia de libvirt aislada por usuario) en vez
# de qemu:///system (donde realmente viven las redes/dominios que ves
# con virsh). Mismo tipo de bug que ya vimos con "virsh list --all"
# saliendo vacio sin sudo -- dos mundos separados de libvirt.
echo "==> [$NODE_NAME] Creando dominio libvirt..."
sudo virt-install \
  --connect qemu:///system \
  --name "$NODE_NAME" \
  --memory 1024 \
  --vcpus 1 \
  --disk path="$NODE_DISK",device=disk,bus=virtio \
  --disk path="$SEED_ISO",device=cdrom \
  --network network="$NETWORK_NAME",model=virtio \
  --os-variant almalinux9 \
  --import \
  --noautoconsole \
  --graphics none

echo "==> [$NODE_NAME] Dominio creado. IP esperada: ${NODE_IP}"
