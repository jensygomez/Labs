# engine/vm_cloner.sh
#!/bin/bash
set -euo pipefail

VM_NAME="$1"
CLOUDINIT_DIR="$2"

# Extraer LAB_ID del nombre VM (lab-j01-v01 → J01)
LAB_ID=$(echo "$VM_NAME" | sed 's/lab-[jps]\([0-9]*\)-.*/\1/')

BASE_VM_NAME="rocky9_base"
BASE_DISK="/var/lib/libvirt/images/rocky9_base.qcow2"
IMAGES_DIR="/var/lib/libvirt/images"
ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"

OVERLAY_DISK="${IMAGES_DIR}/${VM_NAME}.qcow2"

echo "🚀 Creando laboratorio '$VM_NAME' usando overlay qcow2"
echo "📀 Disco base: $BASE_DISK"
echo "📀 Overlay:    $OVERLAY_DISK"

# 1. Verificaciones
if [ ! -f "$BASE_DISK" ]; then
  echo "❌ Disco base no encontrado: $BASE_DISK"
  exit 1
fi

if virsh dominfo "$VM_NAME" >/dev/null 2>&1; then
  echo "❌ La VM '$VM_NAME' ya existe"
  exit 1
fi

# 2. Crear overlay qcow2
echo "🧬 Creando overlay qcow2..."
qemu-img create -f qcow2 -F qcow2 -b "$BASE_DISK" "$OVERLAY_DISK"

# 3. AGREGAR CLAVE SSH al cloud-init (ANTES del ISO)
echo "🔑 Agregando clave SSH RHCSA Labs..."
SSH_KEY="/home/jensy/Labs/.ssh/id_rhcsalabs.pub"
if [ -f "$SSH_KEY" ]; then
  echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByFDKwjMDeGJ5GRhXmZHa75h7dK9JcPHvWWtesSO3/x RHCSA Storage Labs" >> "$CLOUDINIT_DIR/authorized_keys"
else
  echo "⚠️  Clave SSH no encontrada, usando solo config base"
fi

# 4. Crear ISO cloud-init (AHORA INCLUYE LA CLAVE)
CLOUDINIT_ISO="${IMAGES_DIR}/${VM_NAME}-cloudinit.iso"
echo "☁️  Creando ISO cloud-init..."
genisoimage -quiet -output "$CLOUDINIT_ISO" -volid cidata -joliet -rock "$CLOUDINIT_DIR/"

# 5. Crear VM
echo "☁️  Definiendo VM '$VM_NAME'..."
virt-install \
  --name "$VM_NAME" \
  --memory 2048 \
  --vcpus 2 \
  --os-variant rocky9 \
  --disk path="$OVERLAY_DISK",format=qcow2,bus=virtio \
  --disk path="$CLOUDINIT_ISO",device=cdrom \
  --network network=default,model=virtio \
  --import \
  --noautoconsole

# Cleanup
rm -f "$CLOUDINIT_ISO"
echo "✅ Laboratorio '$VM_NAME' creado correctamente"
