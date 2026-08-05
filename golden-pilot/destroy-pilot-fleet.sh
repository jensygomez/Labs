#!/usr/bin/env bash
# destroy-pilot-fleet.sh
set -o errexit
set -o pipefail

NODES=("node01" "node02" "node03" "node04")
IMG_DIR="$HOME/vm-images"

echo "==> Destruyendo flota del laboratorio..."
for node in "${NODES[@]}"; do
    echo "==> Limpiando $node..."
    sudo virsh --connect qemu:///system destroy "$node" 2>/dev/null || true
    sudo virsh --connect qemu:///system undefine "$node" --remove-all-storage 2>/dev/null || true
    rm -rf "$IMG_DIR/$node"
done

echo "==> Flota destruida y discos eliminados."
