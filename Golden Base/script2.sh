#!/bin/bash
#==============================================================================
# Script: setup-network-lab.sh
# Descripción: Configuración persistente de topología de red con namespaces
# Autor: Jensy Gomez
# Fecha: 2026-01-26
# Versión: 0.1
#
#                    INTERNET
#                      ↓ WAN /30
#                ┌───────────┐ 10.255.255.1
#                │  EDGE-1   │
#                └─────┬─────┘
#                      │
#                ┌─────┴────┐ 10.255.255.2 (WAN) | 10.1.1.1/24 (LAN)
#                │  CORE-1  │  ← L3 ROUTER
#                │          │ Trunk VLANs 10,20,30,40
#                └────┬─────┘
#                     │ Trunk 802.1q (10,20,30,40)
#                     │
#┌────────────────────┴──────────────────┐
#│              ACCESS LAYER             │
#├───────────────────────────────────────┤
#│SW-PROD   │ SW-ADM  │ SW-SER │ SW-TI   │
#│VLAN10    │ VLAN20  │ VLAN30 │ VLAN40  │
#├──────────┼─────────┼────────┼─────────┤
#│WEB       │ ANSIBLE │ DEV-IN │ CLI     │
#│10.10...  │ 10.0... │ 30...  │ 10.0..  │
#│DATA      │ CLI     │ DEV-ST │ MONITOR │
#│20.0...   │ 0.100   │ .31    │ 10.10.  │
#└──────────┴─────────┴────────┴─────────┘


# FASES DEL MOTOR
# ✔ Namespaces (hecho é idempotente)
# ✔ Cables veth (hecho é idempotente)
# ✔ IPs (hecho é idempotente)
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
NS_EDGE_1="EDGE-1"
NS_CORE_1="CORE-1"
# Lista para iterar (opcional, para compatibilidad)
NAMESPACES=(
  "$NS_EDGE_1"
  "$NS_CORE_1"
)
# ------------------------------------------------------------------------------
# B - Modelo de Cables (usando VARIABLES)
# Formato: $NS_A:$INTERFACE_A:$NS_B:$INTERFACE_B
# ------------------------------------------------------------------------------
CABLES=(
  "$NS_EDGE_1:eth0:$NS_CORE_1:eth0"
)
# ------------------------------------------------------------------------------
# C - Modelo de IPs
# Formato: $NAMESPACE:$INTERFACE:$IP_CIDR
# ------------------------------------------------------------------------------
IPS=(
  "$NS_EDGE_1:eth0:10.255.255.1/30"
  "$NS_CORE_1:eth0:10.255.255.2/30"
)
# ------------------------------------------------------------------------------
# D - Modelo de Rutas
# Formato:
# $NAMESPACE:$DESTINO:$VIA
# ------------------------------------------------------------------------------
ROUTES=(
  "$NS_EDGE_1:default:10.255.255.2"
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
      ip netns exec "$ns" ip link set lo up
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
VETH_COUNTER_FILE="/tmp/veth_counter"
if [[ ! -f "$VETH_COUNTER_FILE" ]]; then echo 0 > "$VETH_COUNTER_FILE"; fi
ensure_cable(){
  local ns_a="$1" if_a="$2" ns_b="$3" if_b="$4"
  if ! ns_exists "$ns_a" || ! ns_exists "$ns_b"; then
    echo "❌ Namespaces faltantes"
    return 1
  fi
  if ip netns exec "$ns_a" ip link show "$if_a" 2>/dev/null 1>&2 &&
     ip netns exec "$ns_b" ip link show "$if_b" 2>/dev/null 1>&2; then
    echo "✔ Cable existe"
    return 0
  fi
  echo "🔗 Creando cable..."
  local counter=$(cat "$VETH_COUNTER_FILE" 2>/dev/null || echo 0)
  local temp_a="veth${ns_a//-}a${counter}"
  local temp_b="veth${ns_b//-}b${counter}"
  ((counter++))
  echo $counter > "$VETH_COUNTER_FILE"
  if ip link add "$temp_a" type veth peer name "$temp_b"; then
    ip link set "$temp_a" netns "$ns_a"
    ip link set "$temp_b" netns "$ns_b"
    ip netns exec "$ns_a" ip link set "$temp_a" name "$if_a" up || true
    ip netns exec "$ns_b" ip link set "$temp_b" name "$if_b" up || true
    echo "✅ Cable UP ($temp_a ↔ $temp_b)"
  else
    echo "❌ FALLO veth"
    ip link delete "$temp_a" 2>/dev/null || true
    return 1
  fi
  return 0
}
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

# ------------------------------------------------------------------------------
# PRIMITIVA 4: ENSURE ROUTE
# ------------------------------------------------------------------------------
ensure_route(){
  local ns="$1"
  local dest="$2"
  local via="$3"
  if ! ns_exists "$ns"; then
    echo "❌ Namespace $ns no existe"
    return 1
  fi
  # Normalizar Destino
  local route_dest
  if [[ "$dest" == "default" ]]; then 
    route_dest="default"
  else  
    route_dest="$dest"
  fi
  # Ruta ya Existe...?
  if ip netns exec "$ns" ip route show | grep -qw "$route_dest via $via"; then
    echo  "✔ Ruta $route_dest via $via ya existe en $ns"
    return 0
  fi
  # Agregar Ruta
  ip netns exec "$ns" ip route add "$route_dest" via "$via"
  echo "+ Ruta $route_dest via $via agregada en $ns"
}

# ==============================================================================
# BLOQUE 5 - CONVERGENCIAS
# ==============================================================================
# ------------------------------------------------------------------------------
# FASE 1: CONVERGENCIA DE NAMESPACES
# ------------------------------------------------------------------------------
fase_namespaces(){
  echo "[FASE 1] Namespaces..."
  for ns in "${NAMESPACES[@]}"; do
    if ! ensure_namespaces "$ns"; then
      exit 1
    fi
  done
  sleep 1
}
# ------------------------------------------------------------------------------
# FASE 2: CONVERGENCIA DE CABLES
# ------------------------------------------------------------------------------
fase_cables(){
  echo "[FASE 2] Cables..."
  for c in "${CABLES[@]}"; do
    IFS=":" read -r ns_a if_a ns_b if_b <<< "$c"
    if ! ensure_cable "$ns_a" "$if_a" "$ns_b" "$if_b"; then
      exit 1
    fi
  done
  sleep 1
}

# ------------------------------------------------------------------------------
# FASE 3: CONVERGENCIA DE IP's
# ------------------------------------------------------------------------------
fase_ips(){
  echo "[FASE 3] IP's..."
  for ipdef in "${IPS[@]}";do
    IFS=":" read -r ns iface ip_cidr <<< "$ipdef"
    if ! ensure_ip "$ns" "$iface" "$ip_cidr"; then
      exit 1
    fi
  done  
  sleep 1
}

# ------------------------------------------------------------------------------
# FASE 4: CONVERGENCIA DE RUTAS
# ------------------------------------------------------------------------------
fase_rutas(){
  echo "[FASE 4] Rutas..."
  for r in "${ROUTES[@]}"; do
    IFS=":" read -r ns dest via <<< "$r"
    if ! ensure_route "$ns" "$dest" "$via"; then
      exit 1
    fi
  done
  sleep 1
}


# ==============================================================================
# BLOQUE 100- MAIN ( MOTOR MINIMO FUNCIONAL)
# ==============================================================================

run_engine(){
  echo "🚀 Iniciando motor de topología..."
  echo "----------------------------------------"
  
  fase_namespaces
  echo "----------------------------------------"
  
  fase_cables
  echo "----------------------------------------"

  fase_ips
  echo "----------------------------------------"

  fase_rutas
  echo "----------------------------------------"
  
  echo "✅ Topología desplegada exitosamente"
  echo ""
  echo "Resumen:"
  for ns in "${NAMESPACES[@]}"; do
    echo "--- $ns ---"
    ip netns exec "$ns" ip -brief addr show
    ip netns exec "$ns" ip route
    echo ""
  done
}


test_idempotency(){
  local runs=50
  echo "🧪 Iniciando test de idempotencia ($runs ejecuciones)"
  echo "----------------------------------------"

  for i in $(seq 1 "$runs"); do
    echo "▶ Test run #$i"
    if ! run_engine >/dev/null 2>&1; then
      echo "❌ FALLO en ejecución #$i"
      exit 1
    fi
  done

  echo "----------------------------------------"
  echo "✅ Test de idempotencia SUPERADO ($runs ejecuciones)"
}



menu(){
  while true; do
    echo ""
    echo "=============================="
    echo " Network Lab - Control Panel"
    echo "=============================="
    echo "1) Ejecutar motor"
    echo "2) Test de idempotencia (50x)"
    echo "3) Salir"
    echo "------------------------------"
    read -rp "Selecciona una opción: " opt

    case "$opt" in
      1)
        run_engine
        ;;
      2)
        test_idempotency
        ;;
      3)
        echo "👋 Saliendo"
        exit 0
        ;;
      *)
        echo "❌ Opción inválida"
        ;;
    esac
  done
}


main(){
  menu
}

main "$@"
