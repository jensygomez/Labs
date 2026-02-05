#!/bin/bash
# network-engine/lib/vlan.sh
ensure_vlan() {
  local ns="$1"
  local parent_if="$2"
  local vlan_id="$3"
  local ip_cidr="$4"
  local vlan_if="${parent_if}.${vlan_id}"

  # 1. Namespace debe existir
  if ! ns_exists "$ns"; then
    return 1   # namespace inexistente
  fi

  # 2. Crear VLAN si no existe
  if ! ip netns exec "$ns" ip link show "$vlan_if" &>/dev/null; then
    ip netns exec "$ns" ip link add link "$parent_if" name "$vlan_if" type vlan id "$vlan_id"
    ip netns exec "$ns" ip link set "$vlan_if" up
  fi

  # 3. Asignar IP si no está
  if ! ip netns exec "$ns" ip addr show dev "$vlan_if" | grep -q "$ip_cidr"; then
    ip netns exec "$ns" ip addr add "$ip_cidr" dev "$vlan_if"
  fi

  return 0
}
