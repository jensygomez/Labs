#!/bin/bash
# network-engine/lib/vlan.sh
set -Eeuo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/topology/lab.conf"

create_vlan() {
  local ns="$1"
  local parent_if="$2"
  local vlan_id="$3"
  local ip_cidr="$4"
  local vlan_if="${parent_if}.${vlan_id}"

  echo "  🏷️  VLAN $vlan_id en $ns ($vlan_if)"

  # 1. Creaar la interfaz VLAN ligada a la fisica
  ip netns exec "$ns" ip link add link "$parent_if" name "$vlan_if" type vlan id "$vlan_id"

  # 2. Asignar la IP
  ip netns exec "$ns" ip addr add "$ip_cidr" dev "$vlan_if"

  # 3. Levantar la IP
  ip netns exec "$ns" ip linkx set "$vlan_if" up

}