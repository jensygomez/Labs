#!/bin/bash
# network-engine/phases/05-forwarding.sh
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/idempotency.sh"
source "$BASE_DIR/lib/forwarding.sh"
source "$BASE_DIR/topology/lab.conf"

run_phase(){
    echo "[FASE 5] Forwarding & Kernel..."
    for ns in "${ROUTERS[@]}";do
        ensure_forwarding "$ns"
    done
}