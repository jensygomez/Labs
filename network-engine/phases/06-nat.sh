#!/bin/bash
# network-engine/phases/06-nat.sh
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/idempotency.sh"
source "$BASE_DIR/lib/nat.sh"
source "$BASE_DIR/topology/lab.conf"

run_phase(){
    echo "[FASE 6] Nat & Egress..."
    for nat in "${NAT_ROUTERS[@]}"; do
        IFS=":" read -r ns iface <<< "$nat"
        echo "  Configurando NAT para $ns en interfaz $iface"
        ensure_nat "$ns" "$iface"
    done
}