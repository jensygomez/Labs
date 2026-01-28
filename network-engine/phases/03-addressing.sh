#!/bin/bash
# network-engine/phases/03-addressing.sh

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/idempotency.sh"
source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/lib/addressing.sh"
source "$BASE_DIR/topology/lab.conf"


run_phase() {
  echo "[FASE 3] IPs"
  for i in "${IPS[@]}"; do
    IFS=":" read -r ns ifc ip <<< "$i"
    ensure_ip "$ns" "$ifc" "$ip"
  done
}
