#!/bin/bash
# network-engine/phases/04-routing.sh
run_phase() {
  echo "[FASE 4] Rutas"
  for r in "${ROUTES[@]}"; do
    IFS=":" read -r ns dest via <<< "$r"
    ensure_route "$ns" "$dest" "$via"
  done
    echo
    echo "ejecuntando..."
    sleep 2
    echo
    echo "[FASE 4] ejecutada com sucesso"
    echo "-----------------------------------"
}
