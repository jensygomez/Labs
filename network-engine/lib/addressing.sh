#!/bin/bash
# network-engine/lib/addressing.sh
ensure_ip() {
  local ns="$1"
  local iface="$2"
  local ip_cidr="$3"

  # Namespace debe existir
  ns_exists "$ns" || return 1

  # --- VLAN auto-provisioning ---
  if [[ "$iface" == *.* ]]; then
    local parent_if="${iface%.*}"
    local vlan_id="${iface##*.}"

    # Parent interface debe existir
    if ! ip netns exec "$ns" ip link show "$parent_if" &>/dev/null; then
      return 1
    fi

    # Crear VLAN si no existe
    if ! ip netns exec "$ns" ip link show "$iface" &>/dev/null; then
      ip netns exec "$ns" ip link add link "$parent_if" name "$iface" type vlan id "$vlan_id" || return 1
      ip netns exec "$ns" ip link set "$iface" up || return 1
    fi
  fi

  # Interfaz debe existir (normal o VLAN)
  if ! ip netns exec "$ns" ip link show "$iface" &>/dev/null; then
    return 1
  fi

  # Idempotencia: IP ya presente
  if ip netns exec "$ns" ip addr show dev "$iface" | grep -qw "$ip_cidr"; then
    return 0
  fi

  # Asignar IP
  ip netns exec "$ns" ip addr add "$ip_cidr" dev "$iface"
}
