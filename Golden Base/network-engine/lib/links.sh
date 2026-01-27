#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/topology/lab.conf"

set -Eeuo pipefail

# ------------------------------------------------------------------------------
# PRIMITIVA 2: ENSURE CABLES
# ------------------------------------------------------------------------------
VETH_COUNTER_FILE="/tmp/veth_counter"
if [[ ! -f "$VETH_COUNTER_FILE" ]]; then echo 0 > "$VETH_COUNTER_FILE"; fi
ensure_cable(){
  local ns_a="$1" if_a="$2" ns_b="$3" if_b="$4"
  if ! ns_exists "$ns_a" || ! ns_exists "$ns_b"; then
    echo "❌ Namespaces faltantes"
    return 1
  fi
  if ip netns exec "$ns_a" ip link show "$if_a" 2>/dev/null 1>&2 &&
     ip netns exec "$ns_b" ip link show "$if_b" 2>/dev/null 1>&2; then
    echo "✔ Cable existe"
    return 0
  fi
  echo "🔗 Creando cable..."
  local counter=$(cat "$VETH_COUNTER_FILE" 2>/dev/null || echo 0)
  local temp_a="veth${ns_a//-}a${counter}"
  local temp_b="veth${ns_b//-}b${counter}"
  ((counter++))
  echo $counter > "$VETH_COUNTER_FILE"
  if ip link add "$temp_a" type veth peer name "$temp_b"; then
    ip link set "$temp_a" netns "$ns_a"
    ip link set "$temp_b" netns "$ns_b"
    ip netns exec "$ns_a" ip link set "$temp_a" name "$if_a" up || true
    ip netns exec "$ns_b" ip link set "$temp_b" name "$if_b" up || true
    echo "✅ Cable UP ($temp_a ↔ $temp_b)"
  else
    echo "❌ FALLO veth"
    ip link delete "$temp_a" 2>/dev/null || true
    return 1
  fi
  return 0
}