#!/bin/bash
# network-engine/phases/08-firewall.sh
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/guard.sh"
source "$BASE_DIR/lib/idempotency.sh"
source "$BASE_DIR/lib/firewall.sh"
source "$BASE_DIR/topology/lab.conf"

run_phase() {
  echo "[FASE 7] Firewall"
  for ns in "${FW_NAMESPACES[@]}"; do
    ensure_firewall "$ns"
  done
  echo "✅ Políticas stateful convergidas"
}

