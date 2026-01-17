#!/bin/bash
set -euo pipefail

LEVEL="$1"
LAB_ID="$2"
VARIANT_NAME="$3"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VARIANT_DIR="$ROOT_DIR/scenarios/${LEVEL,,}/${LAB_ID}/cloudinit/${VARIANT_NAME}"

WORKDIR="/mnt/vms/labs/tmp/${LAB_ID}_${VARIANT_NAME}_$(date +%s)"
ISO_PATH="$WORKDIR/${LAB_ID}.iso"

USER_DATA="$VARIANT_DIR/user-data"
META_DATA="$VARIANT_DIR/meta-data"

mkdir -p "$WORKDIR"

# =========================
# Validaciones estrictas
# =========================
[[ -d "$VARIANT_DIR" ]] || {
  echo "❌ Variante no existe: $VARIANT_DIR"
  exit 1
}

[[ -f "$USER_DATA" ]] || {
  echo "❌ Falta user-data en $VARIANT_DIR"
  exit 1
}

[[ -f "$META_DATA" ]] || {
  echo "❌ Falta meta-data en $VARIANT_DIR"
  exit 1
}

# =========================
# Copia directa (sin base)
# =========================
cp "$USER_DATA" "$WORKDIR/user-data"
cp "$META_DATA" "$WORKDIR/meta-data"

# =========================
# ISO cloud-init
# =========================
genisoimage -quiet \
  -output "$ISO_PATH" \
  -volid cidata \
  -joliet -rock \
  "$WORKDIR/user-data" "$WORKDIR/meta-data"

echo "$ISO_PATH"
