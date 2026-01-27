# network-engine/phases/01-netns.sh
#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/topology/lab.conf"
source lib/netns.sh
source topology/lab.conf

run_phase() {
  echo "[FASE 1] Namespaces"
  for ns in "${NAMESPACES[@]}"; do
    ensure_namespace "$ns"
  done
}
