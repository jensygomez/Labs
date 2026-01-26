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


set -e  # Detener el script si hay algún error
set -u  # Detectar variables no definidas

#==============================================================================
# VARIABLES 
#==============================================================================
NS_EDGE="NS-EDGE"



# ==============================================================================
# FUNCIONES PRIMITIVAS (crear_namespace)
# ==============================================================================
log(){
  echo -e "\n[$(date +%H:%M:$S)] $1"
}

# ==============================================================================
# FUNCIONES PRIMITIVAS (crear_namespace)
# ==============================================================================

crear_namespace(){
  local ns="$1"

  if ip netns list | grep -qw "$ns"; then
    echo "NameSpace $ns ya existe"
  else
    ip netns add "$ns" 
    echo "NameSpace $ns creado"
  fi
}



# ==============================================================================
# FASES (fase_crear_namespace)
# ==============================================================================

fase_crear_namespace(){
  log "FASE 1: Creando namespcaes..."
  
  crear_namespace "$NS_EDGE"

  sleep 1
}


# ==============================================================================
# FUNCION MAIN
# ==============================================================================
main() {
  fase_crear_namespace
}

main "$@"



