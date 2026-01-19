#!/bin/bash
set -euo pipefail

# ============================================================================
# vm_cloner.sh
# Crea una VM de laboratorio usando disco completo + cloud-init
# Sin usar XML, usando virt-install --import
# ============================================================================
# ARGUMENTOS:
#   $1 = VM_NAME        (ej: lab-junior)
#   $2 = CLOUDINIT_DIR  (ej: /mnt/vms/labs/tmp/cloudinit/J01-V01)
# ============================================================================

VM_NAME="$1"
CLOUDINIT_DIR="$2"

# ============================================================================
# DISCOS
# ============================================================================
BASE_DISK="/var/lib/libvirt/images/lab-junior.qcow2" # disco completo existente
CLOUDINIT_ISO="/var/lib/libvirt/images/${VM_NAME}-seed.iso"

echo "🚀 Creando laboratorio '$VM_NAME' usando disco completo existente"

# ============================================================================
# VALIDAR PERMISOS
# ============================================================================
if [[ $EUID -ne 0 ]]; then
    if sudo -n true &>/dev/null; then
        SUDO="sudo"
    else
        echo "❌ Este script requiere sudo" >&2
        exit 1
    fi
else
    SUDO=""
fi

# ============================================================================
# VALIDAR EXISTENCIA DE ARCHIVOS
# ============================================================================
[[ -f "$BASE_DISK" ]] || { echo "❌ Disco base no encontrado: $BASE_DISK"; exit 1; }
[[ -f "$CLOUDINIT_DIR/user-data" ]] || { echo "❌ Falta user-data"; exit 1; }
[[ -f "$CLOUDINIT_DIR/meta-data" ]] || { echo "❌ Falta meta-data"; exit 1; }

# ============================================================================
# LIMPIEZA PREVIA
# ============================================================================
if $SUDO virsh dominfo "$VM_NAME" &>/dev/null; then
    echo "⚠️ VM existente detectada. Eliminando..."
    $SUDO virsh destroy "$VM_NAME" 2>/dev/null || true
    $SUDO virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true
fi

$SUDO rm -f "$CLOUDINIT_ISO"

# ============================================================================
# CREAR ISO CLOUD-INIT
# ============================================================================
echo "☁️  Creando ISO cloud-init..."
$SUDO genisoimage -output "$CLOUDINIT_ISO" \
    -volid cidata -joliet -rock \
    "$CLOUDINIT_DIR/user-data" \
    "$CLOUDINIT_DIR/meta-data"

$SUDO chown libvirt-qemu:kvm "$CLOUDINIT_ISO"
$SUDO chmod 644 "$CLOUDINIT_ISO"

# ============================================================================
# CREAR VM CON virt-install (SIN XML)
# ============================================================================
echo "🖥️  Creando VM con virt-install --import..."

sudo virt-install \
  --name lab-j01-v01 \
  --memory 2048 \
  --vcpus 2 \
  --os-variant rocky9 \
  --disk path=/var/lib/libvirt/images/lab-junior.qcow2,format=qcow2,bus=virtio \
  --cdrom /var/lib/libvirt/images/lab-junior-seed.iso \
  --network network=default,model=virtio \
  --graphics vnc,listen=0.0.0.0 \
  --noautoconsole \
  --import



# ============================================================================
# FINAL
# ============================================================================
echo ""
echo "🎉 Laboratorio '$VM_NAME' creado correctamente"
echo "   Disco base     : $BASE_DISK"
echo "   Cloud-init ISO : $CLOUDINIT_ISO"
echo ""
echo "🔍 Para ver la VM:"
echo "   sudo virsh list --all"
echo ""
echo "🔍 Para acceder a la consola:"
echo "   sudo virsh console $VM_NAME"
echo ""
echo "🧹 Para eliminar la VM:"
echo "   sudo virsh destroy $VM_NAME"
echo "   sudo virsh undefine $VM_NAME --remove-all-storage"
