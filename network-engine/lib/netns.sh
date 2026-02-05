#!/bin/bash
# network-engine/lib/netns.sh
ns_exists() {
  # Usamos -w para palabra exacta y enviamos errores a /dev/null
  ip netns list | grep -qw "$1" 2>/dev/null
}

ensure_namespace(){
  local ns="$1"
  if ns_exists "$ns"; then
    #echo "✔ Namespace $ns ya existe"
    return 0
  fi

  if ip netns add "$ns"; then
    ip netns exec "$ns" ip link set lo up
    #echo "➕ Namespace $ns creado"
    return 0
  else
    #echo "❌ Error fatal creando namespace $ns"
    return 1
  fi
}