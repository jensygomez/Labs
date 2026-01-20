#!/bin/bash
set -euo pipefail

# ============================================================================
# vm_cloner.sh — MODELO DEFINITIVO
# Clona una VM base REAL y le inyecta cloud-init
# ============================================================================
# ARGUMENTOS:
#   $1 = VM_NAME        (ej: lab-j01-v01)
#   $2 = CLOUDINIT_DIR  (ej: /mnt/vms/labs/tmp/cloudinit/J01-V01)
# ============================================================================

VM_NAME="$1"
CLOUDINIT_DIR="$2"

BASE_VM="rocky9_base"
IMAGES_DIR="/var/lib/libvirt/images"

VM_DISK="${IMAGES_DIR}/${VM_NAME}.qcow2"
CLOUDINIT_ISO="${IMAGES_DIR}/${VM_NAME}-seed.iso"

echo "🚀 Creando laboratorio '$VM_NAME' desde VM base '$BASE_VM'"

# ============================================================================
# VALIDACIONES
# ============================================================================
command -v virt-clone >/dev/null || { echo "❌ virt-clone no encontrado"; exit 1; }
command -v genisoimage >/dev/null || { echo "❌ genisoimage no encontrado"; exit 1; }
command -v virsh >/dev/null || { echo "❌ virsh no encontrado"; exit 1; }

virsh dominfo "$BASE_VM" &>/dev/null || {
  echo "❌ VM base '$BASE_VM' no existe"
  exit 1
}

[[ -f "$CLOUDINIT_DIR/user-data" ]] || { echo "❌ Falta user-data"; exit 1; }
[[ -f "$CLOUDINIT_DIR/meta-data" ]] || { echo "❌ Falta meta-data"; exit 1; }

# ============================================================================
# LIMPIEZA PREVIA
# ============================================================================
if virsh dominfo "$VM_NAME" &>/dev/null; then
  echo "⚠️ VM existente detectada. Eliminando..."
  virsh destroy "$VM_NAME" 2>/dev/null || true
  virsh undefine "$VM_NAME" --remove-all-storage
fi

rm -f "$VM_DISK" "$CLOUDINIT_ISO"

# ============================================================================
# 1. CLONAR VM BASE (XML + DISCO)
# ============================================================================
echo "🧬 Clonando VM base..."

virt-clone \
  --original "$BASE_VM" \
  --name "$VM_NAME" \
  --file "$VM_DISK"

# ============================================================================
# 2. CREAR ISO CLOUD-INIT
# ============================================================================
echo "☁️  Creando ISO cloud-init..."

genisoimage \
  -output "$CLOUDINIT_ISO" \
  -volid cidata \
  -joliet -rock \
  "$CLOUDINIT_DIR/user-data" \
  "$CLOUDINIT_DIR/meta-data"

chown libvirt-qemu:libvirt-qemu "$CLOUDINIT_ISO"
chmod 644 "$CLOUDINIT_ISO"

# ============================================================================
# 3. ADJUNTAR ISO A LA VM
# ============================================================================
echo "📎 Adjuntando cloud-init a la VM..."

virsh attach-disk "$VM_NAME" \
  "$CLOUDINIT_ISO" \
  sda \
  --type cdrom \
  --mode readonly \
  --persistent

# ============================================================================
# 4. ARRANCAR VM
# ============================================================================
echo "▶️ Iniciando VM..."
virsh start "$VM_NAME"

echo ""
echo "✅ Laboratorio '$VM_NAME' creado correctamente"
echo "   Disco      : $VM_DISK"
echo "   Cloud-init : $CLOUDINIT_ISO"
echo ""
echo "🔍 IP:"
echo "   virsh domifaddr $VM_NAME"
