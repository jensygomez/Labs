#!/bin/bash
# network-engine/phases/01-netns.sh
run_phase() {
  echo "[FASE 1] Namespaces"
  for ns in "${NAMESPACES[@]}"; do
    ensure_namespace "$ns"
  done
  sleep 2
  echo "[FASE 1 ejecutada com sucesso"
}
