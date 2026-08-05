#!/usr/bin/env bash
# destroy-pilot-fleet.sh
set -o errexit
set -o pipefail

NODES=("node01" "node02" "node03" "node04")
IMG_DIR="$HOME/vm-images"

echo "==> Destruyendo dominios y limpiando discos..."
for node in "${NODES[@]}"; do
    echo "==> Limpiando $node..."
    sudo virsh --connect qemu:///system destroy "$node" 2>/dev/null || true
    sudo virsh --connect qemu:///system undefine "$node" --remove-all-storage 2>/dev/null || true
    sudo virsh --connect qemu:///session destroy "$node" 2>/dev/null || true
    sudo virsh --connect qemu:///session undefine "$node" --remove-all-storage 2>/dev/null || true
    rm -rf "$IMG_DIR/$node"
done

# Opcional: Limpiar el known_hosts de estas IPs automáticamente
ssh-keygen -f ~/.ssh/known_hosts -R 192.168.122.11 2>/dev/null || true
ssh-keygen -f ~/.ssh/known_hosts -R 192.168.122.12 2>/dev/null || true
ssh-keygen -f ~/.ssh/known_hosts -R 192.168.122.13 2>/dev/null || true
ssh-keygen -f ~/.ssh/known_hosts -R 192.168.122.14 2>/dev/null || true

echo "==> Limpieza completada."
