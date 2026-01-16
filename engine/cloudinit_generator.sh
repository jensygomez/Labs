#!/bin/bash
set -euo pipefail

LEVEL="$1"
LAB_ID="$2"
VARIANT_NAME="$3"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LAB_CLOUDINIT="$ROOT_DIR/scenarios/${LEVEL,,}/${LAB_ID}/cloudinit"

BASE_DIR="$LAB_CLOUDINIT/base"
VARIANT_DIR="$LAB_CLOUDINIT/$VARIANT_NAME"

WORKDIR="/mnt/vms/labs/tmp/${LAB_ID}_${VARIANT_NAME}_$(date +%s)"
ISO_PATH="$WORKDIR/${LAB_ID}.iso"

mkdir -p "$WORKDIR"

# Validaciones
[[ -d "$BASE_DIR" ]] || { echo "❌ base no existe"; exit 1; }
[[ -d "$VARIANT_DIR" ]] || { echo "❌ variante no existe"; exit 1; }

# Base SIEMPRE
cp "$BASE_DIR/user-data" "$WORKDIR/user-data"
cp "$BASE_DIR/meta-data" "$WORKDIR/meta-data"

# Variante SOBREESCRIBE si define
[[ -f "$VARIANT_DIR/user-data" ]] && cp "$VARIANT_DIR/user-data" "$WORKDIR/user-data"
[[ -f "$VARIANT_DIR/meta-data" ]] && cp "$VARIANT_DIR/meta-data" "$WORKDIR/meta-data"

# ISO cloud-init
genisoimage -quiet \
  -output "$ISO_PATH" \
  -volid cidata \
  -joliet -rock \
  "$WORKDIR/user-data" "$WORKDIR/meta-data"

echo "$ISO_PATH"

