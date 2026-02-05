#!/bin/bash
# network-engine/phases/04-routing.sh
run_phase() {
  echo "[FASE 4] ejecutando Rutas"
  for r in "${ROUTES[@]}"; do
    IFS=":" read -r ns dest via <<< "$r"
    ensure_route "$ns" "$dest" "$via"
  done
    sleep 2
    echo "[FASE 4] ejecutada com sucesso"
    echo "-----------------------------------"
}
