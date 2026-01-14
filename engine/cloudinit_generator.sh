#!/bin/bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Uso: $0 <nivel> <lab_id> <variant>"
    exit 1
fi

LEVEL="$1"
LAB_ID="$2"
VARIANT="$3"

ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$ENGINE_DIR/.." && pwd)"
TMP_DIR="$ROOT_DIR/tmp"

mkdir -p "$TMP_DIR"

SCENARIO_DIR="$ROOT_DIR/scenarios/${LEVEL,,}/$LAB_ID/cloudinit"
USER_DATA="$SCENARIO_DIR/$VARIANT.yml"
META_DATA="$ROOT_DIR/scenarios/${LEVEL,,}/$LAB_ID/metadata.yaml"

[[ ! -f "$USER_DATA" ]] && { echo "Error: $USER_DATA no encontrado"; exit 1; }
[[ ! -f "$META_DATA" ]] && { echo "Error: $META_DATA no encontrado"; exit 1; }

ISO_FILE="$TMP_DIR/${LAB_ID}_${VARIANT}.iso"

genisoimage -output "$ISO_FILE" -volid cidata -joliet -rock "$USER_DATA" "$META_DATA"

echo "$ISO_FILE"
