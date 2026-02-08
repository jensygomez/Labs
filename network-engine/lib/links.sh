#!/bin/bash
# network-engine/lib/links.sh
VETH_COUNTER_FILE="/tmp/veth_counter"
[[ -f "$VETH_COUNTER_FILE" ]] || echo 0 > "$VETH_COUNTER_FILE"

ensure_cable() {
  local ns_a="$1" if_a="$2" ns_b="$3" if_b="$4"

  # Precondiciones
  ns_exists "$ns_a" || { echo "❌ $ns_a no existe"; return 1; }
  ns_exists "$ns_b" || { echo "❌ $ns_b no existe"; return 1; }

  # Idempotencia
  if ip netns exec "$ns_a" ip link show "$if_a" &>/dev/null &&
     ip netns exec "$ns_b" ip link show "$if_b" &>/dev/null; then
     echo "✔ Cable $ns_a:$if_a ↔ $ns_b:$if_b existe"
    return 0
  fi

  echo "🔗 Creando cable $ns_a:$if_a ↔ $ns_b:$if_b"

  local counter
  counter=$(<"$VETH_COUNTER_FILE")
  echo $((counter + 1)) > "$VETH_COUNTER_FILE"

  local veth_a="v${counter}a"
  local veth_b="v${counter}b"

  # Crear par veth (manejo explícito de error)
  if ! ip link add "$veth_a" type veth peer name "$veth_b"; then
    echo "❌ ip link add falló"
    return 1
  fi

  ip link set "$veth_a" netns "$ns_a"
  ip link set "$veth_b" netns "$ns_b"

  ip netns exec "$ns_a" ip link set "$veth_a" name "$if_a" up
  ip netns exec "$ns_b" ip link set "$veth_b" name "$if_b" up

  echo "✅ Cable UP ($if_a ↔ $if_b)"
}
