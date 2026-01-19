#!/bin/bash
set -euo pipefail

# ============================================================================
# vm_cloner.sh
# Crea una VM de laboratorio usando qcow2 backing file + cloud-init
# ============================================================================
# ARGUMENTOS:
#   $1 = VM_NAME        (ej: lab-j01-v01)
#   $2 = CLOUDINIT_DIR  (ej: /mnt/vms/labs/tmp/cloudinit/J01-V01)
# ============================================================================

VM_NAME="$1"
CLOUDINIT_DIR="$2"

BASE_DISK="/mnt/vms/rocky9_base.qcow2"
VM_DISK="/var/lib/libvirt/images/${VM_NAME}.qcow2"
CLOUDINIT_ISO="/var/lib/libvirt/images/${VM_NAME}-seed.iso"

echo "🚀 Creando laboratorio '$VM_NAME' (overlay + cloud-init)"

# ============================================================================
# PERMISOS
# ============================================================================
if [[ $EUID -ne 0 ]]; then
  if sudo -n true 2>/dev/null; then
    SUDO="sudo"
  else
    echo "❌ Este script requiere sudo" >&2
    exit 1
  fi
else
  SUDO=""
fi

# ============================================================================
# DEPENDENCIAS
# ============================================================================
for cmd in virsh qemu-img genisoimage; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ Comando requerido no encontrado: $cmd" >&2
    exit 1
  fi
done

# ============================================================================
# VALIDACIONES
# ============================================================================
echo "🔍 Validando insumos..."

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

$SUDO rm -f "$VM_DISK" "$CLOUDINIT_ISO"

# ============================================================================
# 1. CREAR OVERLAY QCOW2
# ============================================================================
echo "💾 Creando overlay qcow2 (backing file)..."

$SUDO qemu-img create -f qcow2 -F qcow2 \
  -b "$BASE_DISK" \
  "$VM_DISK"

$SUDO chown libvirt-qemu:kvm "$VM_DISK"
$SUDO chmod 644 "$VM_DISK"

echo "   Overlay creado: $VM_DISK"
echo "   Base: $BASE_DISK"

# ============================================================================
# 2. CREAR ISO CLOUD-INIT
# ============================================================================
echo "☁️  Creando ISO cloud-init..."

$SUDO genisoimage -output "$CLOUDINIT_ISO" \
  -volid cidata -joliet -rock \
  "$CLOUDINIT_DIR/user-data" \
  "$CLOUDINIT_DIR/meta-data"

$SUDO chown libvirt-qemu:kvm "$CLOUDINIT_ISO"
$SUDO chmod 644 "$CLOUDINIT_ISO"

# ============================================================================
# 3. DEFINIR VM (XML INLINE)
# ============================================================================
echo "🧩 Definiendo dominio libvirt..."

$SUDO virsh define /dev/stdin <<EOF
<domain type='kvm'>
  <name>${VM_NAME}</name>
  <memory unit='MiB'>2048</memory>
  <vcpu>2</vcpu>

  <os>
    <type arch='x86_64'>hvm</type>
  </os>

  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='${VM_DISK}'/>
      <target dev='vda' bus='virtio'/>
    </disk>

    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='${CLOUDINIT_ISO}'/>
      <target dev='hdb' bus='ide'/>
      <readonly/>
    </disk>

    <interface type='network'>
      <source network='default'/>
      <model type='virtio'/>
    </interface>

    <console type='pty'/>
    <graphics type='vnc' autoport='yes'/>
  </devices>
</domain>
EOF

# ============================================================================
# 4. INICIAR VM
# ============================================================================
echo "▶️ Iniciando VM..."
$SUDO virsh start "$VM_NAME"

# ============================================================================
# FINAL
# ============================================================================
echo ""
echo "🎉 Laboratorio '$VM_NAME' creado correctamente"
echo "   Disco overlay : $VM_DISK"
echo "   Cloud-init    : $CLOUDINIT_ISO"
echo ""
echo "🔍 IP:"
echo "   sudo virsh domifaddr $VM_NAME"
echo ""
echo "🧹 Para eliminar:"
echo "   sudo virsh destroy $VM_NAME"
echo "   sudo virsh undefine $VM_NAME --remove-all-storage"
