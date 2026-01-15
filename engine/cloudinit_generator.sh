#!/bin/bash
# ==============================================================================
# CLOUD-INIT GENERATOR v3.0 (yq v4)
# ==============================================================================
# Uso:
#   cloudinit_generator.sh <LEVEL> <LAB_ID> <VARIANT_YAML>
# ==============================================================================

set -euo pipefail

LEVEL="$1"
LAB_ID="$2"
VARIANT_YAML="$3"

# ------------------------------------------------------------------------------
# Verificaciones
# ------------------------------------------------------------------------------
command -v yq >/dev/null || {
    echo "❌ yq v4 no encontrado en PATH" >&2
    exit 1
}

[[ -f "$VARIANT_YAML" ]] || {
    echo "❌ Variante YAML no encontrada: $VARIANT_YAML" >&2
    exit 1
}

mountpoint -q /mnt/vms || {
    echo "❌ /mnt/vms no montado" >&2
    exit 1
}

# ------------------------------------------------------------------------------
# Parseo YAML (yq v4)
# ------------------------------------------------------------------------------
VARIANT_ID=$(yq -r '.variant_id // "1"' "$VARIANT_YAML")
TITLE=$(yq -r '.title // "Lab sin título"' "$VARIANT_YAML")

mapfile -t SERVICES_ENABLED < <(
    yq -r '.enabled[]? // empty' "$VARIANT_YAML"
)

mapfile -t ERROR_COMMANDS < <(
    yq -r '.errors[].commands[]? // empty' "$VARIANT_YAML"
)

VIP_IP=$(yq -r '.. | select(type=="string") | select(test("^192\\.168\\.122\\."))' \
    "$VARIANT_YAML" | head -n1)

# Defaults
[[ ${#SERVICES_ENABLED[@]} -eq 0 ]] && SERVICES_ENABLED=("firewalld")

# ------------------------------------------------------------------------------
# Directorio de trabajo
# ------------------------------------------------------------------------------
WORKDIR="/mnt/vms/labs/tmp/${LEVEL}_${LAB_ID}_v${VARIANT_ID}_$(date +%s)"
ISO_PATH="$WORKDIR/${LAB_ID}_v${VARIANT_ID}.iso"

mkdir -p "$WORKDIR"

# ------------------------------------------------------------------------------
# user-data (cloud-init)
# ------------------------------------------------------------------------------
cat > "$WORKDIR/user-data" <<EOF
#cloud-config
hostname: ${LAB_ID}-v${VARIANT_ID}

users:
  - name: jensy
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: wheel
    shell: /bin/bash
    lock_passwd: false
    passwd: $(openssl passwd -6 "1234")

bootcmd:
  - echo "🔧 LAB $LAB_ID v$VARIANT_ID booting"

runcmd:
  - echo "🚀 Aplicando configuración base"
EOF

# Servicios
for svc in "${SERVICES_ENABLED[@]}"; do
    echo "  - systemctl enable --now $svc || true" >> "$WORKDIR/user-data"
done

# VIP
if [[ -n "$VIP_IP" ]]; then
cat >> "$WORKDIR/user-data" <<EOF
  - nmcli con mod enp1s0 +ipv4.addresses ${VIP_IP}/24
  - nmcli con down enp1s0 || true
  - nmcli con up enp1s0
EOF
fi

# Fallos (EL CORAZÓN DEL LAB)
if [[ ${#ERROR_COMMANDS[@]} -gt 0 ]]; then
    echo "  - echo '💣 Inyectando fallos'" >> "$WORKDIR/user-data"
    for cmd in "${ERROR_COMMANDS[@]}"; do
        echo "  - $cmd" >> "$WORKDIR/user-data"
    done
fi

# Persistencia informativa
cat >> "$WORKDIR/user-data" <<EOF
  - |
    cat > /root/lab_info.txt <<'EOL'
LAB: $LAB_ID
VARIANTE: $VARIANT_ID
TITULO: $TITLE
SERVICIOS: ${SERVICES_ENABLED[*]}
FALLOS INYECTADOS: ${#ERROR_COMMANDS[@]}
EOL

power_state:
  mode: reboot
  condition: true
EOF

# ------------------------------------------------------------------------------
# meta-data
# ------------------------------------------------------------------------------
cat > "$WORKDIR/meta-data" <<EOF
instance-id: ${LAB_ID}-v${VARIANT_ID}
local-hostname: ${LAB_ID}-v${VARIANT_ID}
EOF

# ------------------------------------------------------------------------------
# ISO
# ------------------------------------------------------------------------------
genisoimage -quiet \
    -output "$ISO_PATH" \
    -volid cidata \
    -joliet -rock \
    "$WORKDIR/user-data" "$WORKDIR/meta-data"

# ------------------------------------------------------------------------------
# Salida (IMPORTANTE)
# ------------------------------------------------------------------------------
echo "$ISO_PATH"
