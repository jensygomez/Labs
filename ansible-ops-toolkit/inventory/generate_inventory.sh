#!/usr/bin/env bash
# generate_inventory.sh
#
# Genera un inventario Ansible dinámico a partir de `vagrant ssh-config`
# del lab actualmente levantado. Cada `vagrant up` puede tener distinta
# IP/clave/puerto por VM (aunque ahora las IPs son fijas por diseño,
# la clave SSH privada sí cambia por corrida) — por eso no se hardcodea
# un inventario estático, se regenera cada vez.
#
# Uso: correr desde DENTRO de la carpeta del incidente (donde vive el
#      Vagrantfile), o pasarle la ruta como argumento:
#
#   cd ~/Labs/fleet-incidents/inc-001-boot-fstab-mount-failure
#   bash ~/Labs/ansible-ops-toolkit/inventory/generate_inventory.sh
#
#   # o apuntando a otro lab sin moverte:
#   bash generate_inventory.sh ~/Labs/fleet-incidents/inc-002-slug

set -o errexit
set -o pipefail

LAB_DIR="${1:-$(pwd)}"
OUT_FILE="$(dirname "$0")/production.ini"

if [ ! -f "${LAB_DIR}/Vagrantfile" ]; then
  echo "❌ No se encontró un Vagrantfile en: ${LAB_DIR}"
  echo "   Corré este script desde la carpeta del incidente, o pasala como argumento."
  exit 1
fi

echo "==> Generando inventario desde: ${LAB_DIR}"

{
  echo "[fleet]"
  for node in node01 node02 node03; do
    cfg=$(cd "${LAB_DIR}" && vagrant ssh-config "$node" 2>/dev/null) || continue
    host=$(echo "$cfg" | awk '/HostName/{print $2}')
    port=$(echo "$cfg" | awk '/Port/{print $2}')
    key=$(echo "$cfg"  | awk '/IdentityFile/{print $2}')
    echo "$node ansible_host=${host} ansible_port=${port} ansible_user=vagrant ansible_ssh_private_key_file=${key} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'"
  done

  echo ""
  echo "[storage]"
  cfg=$(cd "${LAB_DIR}" && vagrant ssh-config node04 2>/dev/null) || true
  if [ -n "$cfg" ]; then
    host=$(echo "$cfg" | awk '/HostName/{print $2}')
    port=$(echo "$cfg" | awk '/Port/{print $2}')
    key=$(echo "$cfg"  | awk '/IdentityFile/{print $2}')
    echo "node04 ansible_host=${host} ansible_port=${port} ansible_user=vagrant ansible_ssh_private_key_file=${key} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'"
  fi

  echo ""
  echo "[all_nodes:children]"
  echo "fleet"
  echo "storage"
} > "${OUT_FILE}"

echo "✅ Inventario generado en: ${OUT_FILE}"
