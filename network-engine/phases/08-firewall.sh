#!/bin/bash
# network-engine/phases/08-firewall.sh
run_phase() {
  echo "[FASE 8] Firewall"
  for ns in "${FW_NAMESPACES[@]}"; do
    ensure_firewall "$ns"
  done
    echo
    echo "ejecuntando..."
    sleep 2
    echo
    echo "[FASE 8] ejecutada com sucesso"
    echo "-----------------------------------"  
}

