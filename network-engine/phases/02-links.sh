#!/bin/bash
# network-engine/phases/02-links.sh
run_phase() {
  echo "[FASE 2] ejecutando links"
  for c in "${CABLES[@]}"; do
    IFS=":" read -r a ia b ib <<< "$c"
    ensure_cable "$a" "$ia" "$b" "$ib"
  done
    sleep 2
    echo "[FASE 2] ejecutada com sucesso"
    echo "-----------------------------------"
}
