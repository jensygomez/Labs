#!/bin/bash

# ================================================================================
# LABORATORIO: lab-0003 - NETWORKING AVANZADO
# ================================================================================
# Fecha inicio:  
# Hostname:      ubuntu
# Usuario:       student
# Sistema:       Ubuntu 24.04.4 LTS
# Kernel:        6.8.0-100-generic
# GitHub:        [https://github.com/jensygomez/Labs](https://github.com/jensygomez/Labs)
# ================================================================================

# ===================================================================================
#        TOPOLOGÍA FINAL: INFRAESTRUCTURA DE SERVICIOS Y ESTACIONES (VMs)
# ===================================================================================
#
#                                     INTERNET
#                                        ^
#                                        | (NAT/IP Forwarding)
#                               ┌─────────────────┐
#                               │     CORE-GW     │
#                               │  (IP: 10.0.0.1) │
#                               │  [ Bridge br0 ] │
#                               └────────┬────────┘
#                                        │
#          ┌─────────────────────────────┼─────────────────────────────┐
#          │                             │                             │
#    ┌─────┴──────────┐          ┌───────┴──────────┐          ┌───────┴──────────┐
#    │    NS-SRV      │          │      NS-RH       │          │      NS-SYS      │
#    │ (IP: 10.0.0.10)│          │ (IP: 10.0.0.20)  │          │ (IP: 10.0.0.30)  │
#    │ [Bridge br-srv]│          │ [Bridge br-rh]   │          │ [Bridge br-sys]  │
#    └─────┬────┬─────┘          └────┬────┬────┬───┘          └────────┬─────────┘
#          │    │                     │    │    │                       │
#    ┌─────┴┐ ┌─┴────┐          ┌─────┴┐┌──┴──┐┌┴──────┐          ┌──────┴──────┐
#    │ LDAP │ │  FS  │          │VM-RH1││VM-RH2││VM-RH3│          │VM-SYS-ADM-1 │
#    │(.11) │ │ (.12)│          │(.21) ││(.22) ││(.23) │          │    (.31)    │
#    └──────┘ └──────┘          └──────┘└─────┘└───────┘          └─────────────┘
#
#  [Propósito del Lab]:
#  1. LDAP: Centraliza usuarios (No más 'useradd' manual en cada VM).
#  2. FS:  Servidor NFS/Samba para que /home/usuario esté en todas las VMs.
#  3. SYS: Tu consola para administrar RH y SRV vía SSH.
# ===================================================================================
# ================================================================================
# FILOSOFÍA: ARQUITECTURA DE SISTEMAS LINUX
# ================================================================================
#
# 1. NAMESPACES = AISLAMIENTO QUIRÚRGICO
# 2. BRIDGE = SWITCH EN MEMORIA (sin hardware)
# 3. VETH = CABLES VIRTUALES INVISIBLES
# 4. KERNEL = ÚNICA FUENTE DE VERDAD
#
# ================================================================================

echo ""
echo "🎉 ======================================================"
echo "🎉 LABORATORIO COMPLETADO EXITOSAMENTE!"
echo "✅ Namespaces: $(sudo ip netns list | wc -l)"
echo "✅ Bridges: $(ip link show type bridge | grep -c br)"
echo "🎉 ======================================================"

# ================================================================================
# SESIÓN FINALIZADA ✓
# ================================================================================
