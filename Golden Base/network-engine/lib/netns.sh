#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/topology/lab.conf"

set -Eeuo pipefail

# ------------------------------------------------------------------------------
# PRIMITIVA 1: ENSURE NAMESPACES
# ------------------------------------------------------------------------------
ensure_namespaces(){
  local ns="$1"
  if ns_exists "$ns"; then
    echo "✔ Namespace $ns existe"
    return 0
  else
    if ip netns add "$ns"; then
      ip netns exec "$ns" ip link set lo up
      echo "➕ Namespace $ns creado"
      return 0
    else
      echo "❌ Error creando namespace $ns"
      return 1
    fi
  fi
}