#!/bin/bash
# network-engine/phases/02-links.sh
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$BASE_DIR/lib/idempotency.sh"
source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/lib/links.sh"
source "$BASE_DIR/topology/lab.conf"
source "$BASE_DIR/topology/lab.conf"

run_phase() {
  echo "[FASE 2] Cables"
  for c in "${CABLES[@]}"; do
    IFS=":" read -r a ia b ib <<< "$c"
    ensure_cable "$a" "$ia" "$b" "$ib"
  done
}
