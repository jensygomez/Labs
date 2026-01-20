#!/bin/bash
set -euo pipefail

VM_NAME="$1"
CLOUDINIT_ISO="$2"

BASE_VM_NAME="rocky9_base"
BASE_DISK="/var/lib/libvirt/images/rocky9_base.qcow2"
IMAGES_DIR="/var/lib/libvirt/images"

OVERLAY_DISK="${IMAGES_DIR}/${VM_NAME}.qcow2"

echo "🚀 Creando laboratorio '$VM_NAME' usando overlay qcow2"
echo "📀 Disco base: $BASE_DISK"
echo "📀 Overlay:    $OVERLAY_DISK"

# 1. Verificaciones
if [[ ! -f "$BASE_DISK" ]]; then
  echo "❌ Disco base no encontrado: $BASE_DISK"
  exit 1
fi

if virsh dominfo "$VM_NAME" &>/dev/null; then
  echo "❌ La VM '$VM_NAME' ya existe"
  exit 1
fi

# 2. Crear overlay qcow2
echo "🧬 Creando overlay qcow2..."
qemu-img create \
  -f qcow2 \
  -F qcow2 \
  -b "$BASE_DISK" \
  "$OVERLAY_DISK"

# 3. Crear VM usando virt-install (SIN XML)
echo "☁️  Definiendo VM '$VM_NAME'..."

virt-install \
  --name "$VM_NAME" \
  --memory 2048 \
  --vcpus 2 \
  --os-variant rocky9 \
  --disk path="$OVERLAY_DISK",format=qcow2,bus=virtio \
  --disk path="$CLOUDINIT_ISO",device=cdrom,format=iso \
  --network network=default,model=virtio \
  --import \
  --noautoconsole


echo "✅ Laboratorio '$VM_NAME' creado correctamente"
