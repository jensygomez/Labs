#!/bin/bash
# network-engine/lib/vlan.sh


# ------------------------------------------------------------------------------
# PRIMITIVA: ENSURE VLAN (802.1Q)
# ------------------------------------------------------------------------------
ensure_vlan() {
  local ns="$1"
  local parent_if="$2"
  local vlan_id="$3"
  local ip_cidr="$4"
  local vlan_if="${parent_if}.${vlan_id}"

  # 1. Validación de existencia del Namespace
  if ! ns_exists "$ns"; then
    echo "❌ Namespace $ns no existe para crear VLAN"
  fi

  # 2. Verificar si la sub-interfaz VLAN ya existe
  if ip netns exec "$ns" ip link show "$vlan_if" &>/dev/null; then
    echo "  ✔ VLAN $vlan_id ya existe en $ns ($vlan_if)"
  else
    echo "  🏷️  Creando VLAN $vlan_id en $ns (parent: $parent_if)"
    # Crear la interfaz VLAN etiquetada
    ip netns exec "$ns" ip link add link "$parent_if" name "$vlan_if" type vlan id "$vlan_id"
    # Levantar la interfaz físicamente
    ip netns exec "$ns" ip link set "$vlan_if" up
  fi

  # 3. Validar/Asignar la IP (Idempotencia de direccionamiento)
  if ! ip netns exec "$ns" ip addr show dev "$vlan_if" | grep -q "$ip_cidr"; then
    echo "  + Asignando IP $ip_cidr a $vlan_if"
    ip netns exec "$ns" ip addr add "$ip_cidr" dev "$vlan_if"
  else
    echo "  ✔ IP $ip_cidr ya configurada en $vlan_if"
  fi
}