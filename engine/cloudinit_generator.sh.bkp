#!/bin/bash
# ==============================================================================
# CLOUD-INIT GENERATOR
# ------------------------------------------------------------------------------
# ARCHIVO  : cloudinit_generator.sh
# AUTOR    : Jensy
# AÑO      : 2026
#
# PROPÓSITO:
#   Generar automáticamente una ISO NoCloud para inicializar
#   una VM con cloud-init según lab y variante.
#
# USO:
#   ./cloudinit_generator.sh <nivel> <lab_id> <variant>
#   Devuelve path al ISO generado
# ==============================================================================

set -euo pipefail

# ===============================
# BLOQUE 0 — VALIDACIÓN DE ARGUMENTOS
# ===============================
if [[ $# -ne 3 ]]; then
    echo "Uso: $0 <nivel> <lab_id> <variant>"
    echo "Ejemplo: $0 Junior J01 variant_2"
    exit 1
fi

LEVEL="$1"
LAB_ID="$2"
VARIANT="$3"

# ===============================
# BLOQUE 1 — RUTAS BASE
# ===============================
ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$ENGINE_DIR/.." && pwd)"
TMP_DIR="$ROOT_DIR/tmp"

mkdir -p "$TMP_DIR"

SCENARIO_DIR="$ROOT_DIR/scenarios/${LEVEL,,}/$LAB_ID/cloudinit"  # ${LEVEL,,} -> minúsculas
USER_DATA="$SCENARIO_DIR/$VARIANT.yaml"
META_DATA="$SCENARIO_DIR/metadata.yaml"

[[ ! -f "$USER_DATA" ]] && { echo "Error: no existe $USER_DATA"; exit 1; }
[[ ! -f "$META_DATA" ]] && { echo "Error: no existe $META_DATA"; exit 1; }

# ===============================
# BLOQUE 2 — ISO DE SALIDA
# ===============================
ISO_FILE="$TMP_DIR/${LAB_ID}_${VARIANT}.iso"

# ===============================
# BLOQUE 3 — GENERAR ISO NO CLOUD
# ===============================
genisoimage \
  -output "$ISO_FILE" \
  -volid cidata \
  -joliet -rock \
  "$USER_DATA" "$META_DATA" >/dev/null 2>&1

echo "$ISO_FILE"
