#!/bin/bash
# network-engine/phases/01-netns.sh
source lib/netns.sh
source topology/lab.conf

run_phase() {
  echo "[FASE 1] Namespaces"
  for ns in "${NAMESPACES[@]}"; do
    ensure_namespace "$ns"
  done
}
