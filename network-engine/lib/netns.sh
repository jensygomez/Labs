#!/bin/bash
# network-engine/lib/netns.sh
ns_exists() {
  ip netns list | grep -qw "$1" 2>/dev/null
}

ensure_namespace(){
  local ns="$1"
  if ns_exists "$ns"; then
    echo "✔ Namespace $ns ya existe"
    return 0
  fi

  if ip netns add "$ns"; then
    # 1. Levantar Loopback (Esencial para servicios)
    ip netns exec "$ns" ip link set lo up
    
    # 2. Preparar aislamiento de DNS
    # Linux busca en /etc/netns/[NS_NAME]/resolv.conf antes que en /etc/resolv.conf
    mkdir -p "/etc/netns/$ns"
    
    # Por defecto, heredamos el del host para que tengan internet si hay NAT,
    # en la fase de DNS los re-apuntaremos al SVC-DNS.
    cp /etc/resolv.conf "/etc/netns/$ns/resolv.conf" 2>/dev/null

    echo "➕ Namespace $ns creado (con aislamiento de config)"
    return 0
  else
    echo "❌ Error fatal creando namespace $ns"
    return 1
  fi
}









'''
ns_exists() {
  # Usamos -w para palabra exacta y enviamos errores a /dev/null
  ip netns list | grep -qw "$1" 2>/dev/null
}

ensure_namespace(){
  local ns="$1"
  if ns_exists "$ns"; then
    echo "✔ Namespace $ns ya existe"
    return 0
  fi

  if ip netns add "$ns"; then
    ip netns exec "$ns" ip link set lo up
    echo "➕ Namespace $ns creado"
    return 0
  else
    echo "❌ Error fatal creando namespace $ns"
    return 1
  fi
}
'''