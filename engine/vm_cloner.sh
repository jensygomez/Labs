#!/bin/bash
set -euo pipefail

# ============================================================================
# vm_cloner.sh
# Clona una VM base de libvirt y aplica cloud-init
# ============================================================================
# ARGUMENTOS:
#   $1 = VM_NAME     (ej: lab-j01-v01)
#   $2 = CLOUDINIT_DIR (ej: /mnt/vms/labs/tmp/cloudinit/J01-V01)
# ============================================================================

VM_NAME="$1"
CLOUDINIT_DIR="$2"
BASE_VM="rocky9_base"  # ← Tu VM base

echo "🚀 Creando VM '$VM_NAME' desde '$BASE_VM'..."

# ============================================================================
# VALIDACIONES
# ============================================================================
if ! sudo virsh dominfo "$BASE_VM" >/dev/null 2>&1; then
    echo "❌ VM base '$BASE_VM' no encontrada" >&2
    exit 1
fi

if [[ ! -f "$CLOUDINIT_DIR/user-data" ]] || [[ ! -f "$CLOUDINIT_DIR/meta-data" ]]; then
    echo "❌ Archivos cloud-init no encontrados en $CLOUDINIT_DIR" >&2
    exit 1
fi

# Limpiar si ya existe
if sudo virsh dominfo "$VM_NAME" >/dev/null 2>&1; then
    echo "⚠️  VM '$VM_NAME' ya existe, eliminando..."
    sudo virsh destroy "$VM_NAME" 2>/dev/null || true
    sudo virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true
fi

# ============================================================================
# 1. CREAR DISCO CLOUD-INIT
# ============================================================================
echo "☁️  Creando disco cloud-init..."

CLOUDINIT_ISO="/var/lib/libvirt/images/${VM_NAME}-seed.iso"

# Crear ISO
genisoimage -output "$CLOUDINIT_ISO" -volid cidata -joliet -rock \
    "$CLOUDINIT_DIR/user-data" "$CLOUDINIT_DIR/meta-data" 2>/dev/null

sudo chown libvirt-qemu:kvm "$CLOUDINIT_ISO" 2>/dev/null || true
echo "✅ ISO cloud-init creada"

# ============================================================================
# 2. CLONAR LA VM USANDO VIRT-CLONE
# ============================================================================
echo "📀 Clonando VM..."

# virt-clone con cloud-init
sudo virt-clone \
    --original "$BASE_VM" \
    --name "$VM_NAME" \
    --file "/var/lib/libvirt/images/${VM_NAME}.qcow2" \
    --preserve-data

echo "✅ VM clonada"

# ============================================================================
# 3. AGREGAR DISCO CLOUD-INIT A LA VM
# ============================================================================
echo "🔗 Conectando disco cloud-init..."

# Agregar el CDROM con cloud-init
sudo virsh attach-disk "$VM_NAME" "$CLOUDINIT_ISO" hdb --type cdrom --mode readonly

# ============================================================================
# 4. INICIAR LA VM
# ============================================================================
echo "▶️  Iniciando VM..."
sudo virsh start "$VM_NAME"

# ============================================================================
# 5. INFORMACIÓN FINAL
# ============================================================================
echo ""
echo "🎉 VM '$VM_NAME' creada exitosamente!"
echo ""
echo "📊 Información:"
echo "   Estado: $(sudo virsh domstate "$VM_NAME")"
echo ""
echo "🔍 Para ver la IP (puede tardar unos segundos):"
echo "   sudo virsh domifaddr $VM_NAME"
echo ""
echo "📝 Para conectar por consola:"
echo "   sudo virsh console $VM_NAME"
echo ""
echo "❗ El disco cloud-init se desconectará automáticamente después del primer boot"