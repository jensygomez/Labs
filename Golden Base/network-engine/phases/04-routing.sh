#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/topology/lab.conf"

run_phase() {
  echo "[FASE 4] Rutas"
  for r in "${ROUTES[@]}"; do
    IFS=":" read -r ns dest via <<< "$r"
    ensure_route "$ns" "$dest" "$via"
  done
}
