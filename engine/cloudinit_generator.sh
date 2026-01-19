#!/bin/bash
set -euo pipefail

# ============================================================================
# cloudinit_generator.sh
# Generador SIMPLE y DETERMINÍSTICO de cloud-init
#
# MODELO:
#   - 1 LAB  = 1 VM
#   - 1 VARIANT = lab completo
#   - El user-data NO se modifica
# ============================================================================
#
# ARGUMENTOS:
#   $1 = LEVEL   (ej: junior)
#   $2 = LAB_ID  (ej: J01)
#   $3 = VARIANT (ej: V01)
#
# SALIDA:
#   stdout -> path del directorio cloud-init generado
# ============================================================================

LEVEL="$1"
LAB_ID="$2"
VARIANT="$3"

# ============================================================================
# PATHS
# ============================================================================
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$ROOT_DIR/scenarios/${LEVEL,,}/${LAB_ID}/cloudinit/${VARIANT}"

OUT_BASE="/mnt/vms/labs/tmp/cloudinit"
OUT_DIR="$OUT_BASE/${LAB_ID}-${VARIANT}"

USER_DATA_SRC="$SRC_DIR/user-data"
META_DATA_OUT="$OUT_DIR/meta-data"
USER_DATA_OUT="$OUT_DIR/user-data"

# ============================================================================
# VALIDACIONES
# ============================================================================
[[ -d "$SRC_DIR" ]] || {
  echo "❌ Variant no existe: $SRC_DIR" >&2
  exit 1
}

[[ -f "$USER_DATA_SRC" ]] || {
  echo "❌ user-data no encontrado en $SRC_DIR" >&2
  exit 1
}

# ============================================================================
# CREAR OUTPUT
# ============================================================================
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

# ============================================================================
# COPIAR USER-DATA TAL CUAL
# ============================================================================
cp "$USER_DATA_SRC" "$USER_DATA_OUT"

# ============================================================================
# META-DATA (identidad única)
# ============================================================================
cat > "$META_DATA_OUT" <<EOF
instance-id: lab-${LAB_ID}-${VARIANT}
local-hostname: lab-${LAB_ID}-${VARIANT}
EOF

# ============================================================================
# SALIDA
# ============================================================================
echo "$OUT_DIR"
