#!/bin/bash
# network-engine/phases/08-firewall.sh
run_phase() {
  echo "[FASE 8] ejecutando Firewall"
  for ns in "${FW_NAMESPACES[@]}"; do
    ensure_firewall "$ns"
  done
}

