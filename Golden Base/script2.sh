#!/bin/bash

#==============================================================================
# Script: setup-network-lab.sh
# Descripción: Configuración persistente de topología de red con namespaces
# Autor: Jensy Gomez
# Fecha: 2026-01-26
# Versión: 0.1
#==============================================================================
# INTERNET
#                       ↓
#                 ┌──────────┐
#                 │ NS-EDGE  │ 10.255.255.1 (WAN: dhcp/simulado)
#                 └────┬─────┘
#                      │
#                [BR-EDGE-CORE] 10.255.255.0/30
#                      │
#                 ┌────┴─────┐
#                 │ NS-CORE  │ 10.255.255.2
#                 └─┬──┬──┬──┘
#          ┌────────┘  │  └────────┐
#          │           │           │
#    [BR-CORE-MGMT] [BR-PROD] [BR-DATABASE]
#     10.0.0.0/24   10.10.0/24  10.20.0.0/24
#          │           │           │
#      ┌───┴───┐   ┌───┴───┐   ┌───┴────┐
#  NS-ANSIBLE  │ NS-SRV-WEB│ NS-SRV-DATA│
#  10.0.0.50   │ 10.10.0.10│ 10.20.0.50 │
#  NS-CLI      │ NS-MONITOR│            │
#  10.0.0.100  │ 10.10.0.40│            │
#              └───────────┘            │
#                                       │
#                            [BR-SERVICES]
#                             10.30.0.0/24
#                                  │
#                          ┌───────┴────────┐
#                      NS-DEV-INDIA    NS-DEV-STAGING
#                      10.30.0.30      10.30.0.31

# FASES DEL MOTOR
# ✔ Namespaces (hecho)
# ✔ Cables (veth) idempotentes (hecho)
# IPs (despues)
# Rutas
# Políticas (iptables, nftables)
# Tests automáticos

set -Eeuo pipefail

# ==============================================================================
# BLOQUE 1 - CHECK ROOT
# ==============================================================================
if [[ $EUID -ne 0 ]]; then
  echo "Ejecuta como root"
  exit 1
fi

# ==============================================================================
# BLOQUE 2 - MODELOS GENERALES
# ==============================================================================

# ------------------------------------------------------------------------------
# A - Modelos de NameSpaces
# ------------------------------------------------------------------------------
NAMESPACES=(
  "EDGE-1"
  "CORE-1"
)

# ------------------------------------------------------------------------------
# B - Modelo de Cables
# Formato:
# A:ip_a:B:ip:b:Type[vlan]
# ------------------------------------------------------------------------------
CABLES=(
  "EDGE-1:eth0-edge-1:CORE-1:eth0-core-1"
  "EDGE-1:eth1-edge-1:CORE-1:eth1-core-1"
)
# ------------------------------------------------------------------------------
# C - Modelo de IPs
# ------------------------------------------------------------------------------
IP_CONFIGS=(
    "EDGE-1:v.10:192.168.10.1/24"

)

# ==============================================================================
# BLOQUE 3 - UTILIDADES (MOTOR SILENCIOSO)
# ==============================================================================
ns_exists(){
  ip netns list | grep -qw "$1"
}



# ==============================================================================
# BLOQUE 4 - PRIMITIVAS
# ==============================================================================

# ------------------------------------------------------------------------------
# PRIMITIVA 1: ENSURE NAMESPACES
# ------------------------------------------------------------------------------
ensure_namespaces(){
  local ns="$1"

  if ns_exists "$ns"; then
    echo "✔ Namespace $ns existe"
    return 0
  else
    if ip netns add "$ns"; then
      echo "➕ Namespace $ns creado"
      return 0
    else
      echo "❌ Error creando namespace $ns"
      return 1
    fi
  fi
}

# ------------------------------------------------------------------------------
# PRIMITIVA 2: ENSURE CABLES
# ------------------------------------------------------------------------------
ensure_cable(){
  local ns_a="$1"
  local if_a="$2"
  local ns_b="$3"
  local if_b="$4"

if ip netns exec "$ns_a" ip link show "$if_a" &>/dev/null && ip netns exec "$ns_b" ip link show "$if_b" &>/dev/null; then
  echo "✔ Cable $if_a <--> $if_b existe"
  sleep 1
  return
fi

echo "+ Creando cable $if_a <--> $if_b ..."
sleep 1
ip link add "$if_a" type veth peer name "$if_b"
ip link set "$if_a" netns "$ns_a"
ip link set "$if_b" netns "$ns_b"

ip netns exec "$ns_a" ip link set "$if_a" up
ip netns exec "$ns_b" ip link set "$if_b" up
}
# ==============================================================================
# BLOQUE 5 - CONVERGENCIAS
# ==============================================================================

# ------------------------------------------------------------------------------
# FASE 1: CONVERGENCIA DE NAMESPACES
# ------------------------------------------------------------------------------
fase_namespaces(){
  echo "[FASE 1] Namespaces"
  for ns in "${NAMESPACES[@]}"; do
    if ! ensure_namespaces "$ns"; then
      exit 1
    fi
  done
}
# ------------------------------------------------------------------------------
# FASE 2: CONVERGENCIA DE CABLES
# ------------------------------------------------------------------------------
fase_cables(){
  echo "[FASE 2] Cables"
  for c in "${CABLES[@]}"; do
    IFS=":" read -r ns_a if_a ns_b if_b <<< "$c"
    if ! ensure_cable "$ns_a" "$if_a" "$ns_b" "$if_b"; then
      exit 1
    fi
  done
}

# ==============================================================================
# BLOQUE 100- MAIN ( MOTOR MINIMO FUNCIONAL)
# ==============================================================================
main() {
  fase_namespaces
  fase_cables  

}

main "$@"
