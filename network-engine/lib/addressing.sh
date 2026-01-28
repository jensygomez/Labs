#!/bin/bash
# network-engine/lib/addressing.sh
set -Eeuo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/topology/lab.conf"



# ------------------------------------------------------------------------------
# PRIMITIVA 3: ENSURE IP
# ------------------------------------------------------------------------------
ensure_ip(){
  local ns="$1"
  local iface="$2"
  local ip_cidr="$3"
  # Verificar namespaces
  if ! ns_exists "$ns"; then
    echo "❌ Namespace $ns no existe"
    return 1
  fi
  # Verificar Interfaz
  if ! ip netns exec "$ns" ip link show "$iface" &>/dev/null; then
    echo "❌ Interfaz $iface no existe en $ns"
    return 1
  fi
  # Idempotencia: IP ya Asignada...?
  if ip netns exec "$ns" ip addr show dev "$iface" | grep -qw "$ip_cidr"; then
    echo "+ [$ns] $iface <-- $ip_cidr"
    return 0
  fi
  # Asignar IP
  if ip netns exec "$ns" ip addr add "$ip_cidr" dev "$iface"; then
    echo "+ [$ns] $iface <-- $ip_cidr"
  fi
}