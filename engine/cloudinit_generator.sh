#!/bin/bash
# ==============================================================================
# CLOUD-INIT GENERATOR (prueba mínima)
# ==============================================================================
# Uso: cloudinit_generator.sh <LEVEL> <LAB_ID> <TEMPLATE>
# Devuelve: ruta absoluta del ISO generado
# ==============================================================================

set -euo pipefail

LEVEL="$1"
LAB_ID="$2"
TEMPLATE="$3"

TMP_DIR="$(dirname "$TEMPLATE")/tmp"
mkdir -p "$TMP_DIR"

ISO_PATH="$TMP_DIR/${LAB_ID}_nocloud.iso"

# Crear user-data simple
cat > "$TMP_DIR/user-data" <<EOF
#cloud-config
hostname: ${LAB_ID}
ssh_pwauth: True
users:
  - name: jensy
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    shell: /bin/bash
    lock_passwd: false
    passwd: $(openssl passwd -6 "1234")
EOF

# Crear meta-data vacío
echo "instance-id: $LAB_ID" > "$TMP_DIR/meta-data"
echo "local-hostname: $LAB_ID" >> "$TMP_DIR/meta-data"

# Generar ISO
genisoimage -output "$ISO_PATH" -volid cidata -joliet -rock "$TMP_DIR/user-data" "$TMP_DIR/meta-data"

echo "$ISO_PATH"
