#!/bin/bash
# network-engine/phases/04-routing.sh

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/idempotency.sh"
source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/lib/routing.sh"
source "$BASE_DIR/topology/lab.conf"


run_phase() {
  echo "[FASE 4] Rutas"
  for r in "${ROUTES[@]}"; do
    IFS=":" read -r ns dest via <<< "$r"
    ensure_route "$ns" "$dest" "$via"
  done
}
