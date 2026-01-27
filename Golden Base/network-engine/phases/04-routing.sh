#!/bin/bash
source lib/routing.sh
source topology/lab.conf

run_phase() {
  echo "[FASE 4] Rutas"
  for r in "${ROUTES[@]}"; do
    IFS=":" read -r ns dest via <<< "$r"
    ensure_route "$ns" "$dest" "$via"
  done
}
