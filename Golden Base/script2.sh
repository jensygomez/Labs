#!/bin/bash

#==============================================================================
# Script: setup-network-lab.sh
# Descripción: Configuración persistente de topología de red con namespaces
# Autor: Jensy Gomez
# Fecha: 2026-01-26
# Versión: 0.1
#==============================================================================

set -e # Si CUALQUIER comando falla, detén INMEDIATAMENTE todo el script
set -u # Si intentas usar una variable que NO existe, detén TODO inmediatamente

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

NS_EDGE="NS-EDGE"


# ==============================================================================
# CREAACION DEL ROUTER
# ==============================================================================

ip netns add $NS_EDGE
