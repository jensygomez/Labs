#!/bin/bash
# ==============================================================================
# CLOUD-INIT GENERATOR (prueba mínima) - MODIFICADO PARA DISCO VM
# ==============================================================================
# Uso: cloudinit_generator.sh <LEVEL> <LAB_ID> <TEMPLATE>
# Devuelve: ruta absoluta del ISO generado en /mnt/vms (NO en repo GitHub)
# 
# CAMBIOS:
# - TMP_DIR: Ahora usa /mnt/vms/labs/tmp/ (sdb1 111.8G) en lugar de repo
# - Verifica que /mnt/vms esté montado antes de crear ISOs
# ==============================================================================

set -euo pipefail  # Salir en error, variables indefinidas, fallos de pipe

# ========== PARÁMETROS DE ENTRADA ==========
LEVEL="$1"      # Ej: "junior"
LAB_ID="$2"     # Ej: "J00" 
TEMPLATE="$3"   # Ej: "scenarios/junior/J00/cloudinit/variant_1.yml"

# ========== RUTA FIJA EN DISCO DE VMs ==========
# sdb1 montado en /mnt/vms -> 111.8G disponibles para ISOs
VMS_TMP_DIR="/mnt/vms/labs/tmp/${LEVEL}_${LAB_ID}"
mkdir -p "$VMS_TMP_DIR"  # Crea estructura: /mnt/vms/labs/tmp/junior_J00/

ISO_PATH="$VMS_TMP_DIR/${LAB_ID}_nocloud.iso"  # Salida final del script

# ========== VERIFICAR DISCO DE VMs ==========
if ! mountpoint -q "/mnt/vms"; then
    echo "❌ ERROR: /mnt/vms no montado. Verifica: mount /dev/sdb1 /mnt/vms" >&2
    exit 1
fi

# ========== CREAR ARCHIVOS CLOUD-INIT ==========
# user-data: Configuración del sistema (igual que original)
cat > "$VMS_TMP_DIR/user-data" <<EOF
#cloud-config
hostname: ${LAB_ID}
ssh_pwauth: True  # Permitir login SSH con password
users:
  - name: jensy
    sudo: ALL=(ALL) NOPASSWD:ALL  # Usuario root sin password
    groups: users, admin
    shell: /bin/bash
    lock_passwd: false
    passwd: $(openssl passwd -6 "1234")  # Password: 1234
EOF

# meta-data: Identificación de la instancia VM (igual que original)
echo "instance-id: $LAB_ID" > "$VMS_TMP_DIR/meta-data"
echo "local-hostname: $LAB_ID" >> "$VMS_TMP_DIR/meta-data"

# ========== GENERAR ISO (igual que original) ==========
echo "🔨 Generando ISO en: $ISO_PATH" >&2
genisoimage \
    -output "$ISO_PATH" \
    -volid cidata \
    -joliet \
    -rock \
    "$VMS_TMP_DIR/user-data" \
    "$VMS_TMP_DIR/meta-data"

# ========== RESULTADO ==========
echo "✅ ISO creado: $ISO_PATH" >&2
echo "$ISO_PATH"  # main.sh captura esta línea

