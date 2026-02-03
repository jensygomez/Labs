#!/bin/bash
# network-engine/lib/netns.sh


ns_exists() {
  ip netns list | grep -qW "$1"
}

ensure_namespace(){
  local ns="$1"
  if ns_exists "$ns"; then
    echo "✔ Namespace $ns existe"
    return 0
  fi

  if ip netns add "$ns"; then
    ip netns exec "$ns" ip link set lo up
    echo "➕ Namespace $ns creado"
    return 0
  else
    echo "❌ Error creando namespace $ns"
    return 1
  fi
}