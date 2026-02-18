#!/bin/bash
# ===================================================================================
# LABORATORIO LINUX PARA CERTIFICACIÓN LFCS/LFCE
# Topología: Infraestructura completa con namespaces
# Versión: 2.0 - Escalable y automatizada
print_topology() {
cat <<'EOF'

===================================================================================
TOPOLOGÍA DISTRIBUIDA – LAB DE ARQUITECTURA LINUX
===================================================================================

                          ┌─────────────────────────────────────┐
                          │         INTERNET (8.8.8.8)          │
                          └───────────────┬─────────────────────┘
                                          │
                          ┌───────────────┴─────────────────────┐
                          │            HOST (tu PC)             │
                          │       172.16.255.1/30 (v-wan-gw)    │
                          └───────────────┬─────────────────────┘
                                          │
                                          │ veth pair
                                          │
                      ┌───────────────────┴───────────────────────────┐
                      │           CORE-GW (namespace raíz)            │
                      │       ┌─────────────────────────────┐         │
                      │       │  br0: 10.0.0.1/24           │         │
                      │       │  v-gw-wan: 172.16.255.2/30  │         │
                      │       └─────────────────────────────┘         │
                      └───────────────────┬───────────────────────────┘
                                          |       
           ┌───────────────────┌──────────┘──────────┌──────────────────────┐
           │                   │                     │                      │
  ┌────────┴────────┐ ┌────────┴─────────┐  ┌────────┴────────┐    ┌────────┴────────┐
  │    NS-SRV       │ │      NS-RH       │  │      NS-SYS     │    │     NS-INFRA    │
  │  (Servicios)    │ │   (Recursos H)   │  │      (Admin)    │    │      (Infra)    │
  │                 │ │                  │  │                 │    │                 │
  │  ┌──────────┐   │ │     ┌──────┐     │  │     ┌──────┐    │    │      ┌──────┐   │
  │  │ br-srv   │   │ │     │br-rh │     │  │     │br-sys│    │    │      │br-inf│   │
  │  │(switch L2│   │ │     │(L2)  │     │  │     │(L2)  │    │    │      │(L2)  │   │
  │  └────┬─────┘   │ │     └──┬───┘     │  │     └──┬───┘    │    │      └──┬───┘   │
  └───────┼─────────┘ └────────┼─────────┘  └────────┼────────┘    └─────────┼───────┘
          │                    │                     │                       │
     ┌────┴─────┐         ┌────┴─────┐          ┌────┴─────┐            ┌────┴─────┐
     │SRV-LDAP  │         │PC_1-RH   │          │ PC_1-SYS │            │SRV-DNS   │
     │10.0.0.11 │         │10.0.0.21 │          │10.0.0.31 │            │10.0.0.2  │
     ├──────────┤         ├──────────┤          └──────────┘            ├──────────┤
     │SRV-FS    │         │PC_2-RH   │                                  │SRV-DHCP  │
     │10.0.0.12 │         │10.0.0.22 │                                  │10.0.0.3  │
     └──────────┘         ├──────────┤                                  └──────────┘
                          │PC_3-RH   │
                          │10.0.0.23 │
                          └──────────┘

===================================================================================
PROPÓSITO DEL LAB
===================================================================================
1. LDAP  : Centralización de usuarios (SSSD / PAM / NSS)
2. FS    : NFS o Samba para /home compartido
3. SYS   : Bastión de administración (SSH, Ansible, control)

===================================================================================
FILOSOFÍA
===================================================================================
• Namespaces = Aislamiento quirúrgico
• Bridge     = Switch L2 en memoria
• Veth       = Cable virtual
• Kernel     = Única fuente de verdad
===================================================================================
ESTADO ACTUAL — LAB 01 COMPLETADO
===================================================================================

Componentes creados:

✔ Namespace:
  - CORE-GW

✔ Bridge interno (LAN):
  - br0 (dentro de CORE-GW)
  - IP: 10.0.0.1/24
  - Función: Gateway interno para todos los departamentos

✔ Enlace WAN (CORE-GW ↔ HOST):
  - v-gw-wan  (en CORE-GW)
    • IP: 172.16.255.2/30
  - v-wan-gw  (en HOST)
    • IP: 172.16.255.1/30

✔ Routing:
  - Ruta por defecto en CORE-GW:
    • default via 172.16.255.1 dev v-gw-wan

✔ Kernel & Forwarding (HOST):
  - net.ipv4.ip_forward = 1

✔ NAT (HOST):
  - POSTROUTING MASQUERADE:
    • Origen: 172.16.255.0/30
    • Salida: interfaz física del host (ej: enp1s0)

✔ Conectividad:
  - CORE-GW → HOST: OK
  - CORE-GW → Internet (8.8.8.8): OK

Estado operativo:

→ CORE-GW funciona como:
  • Router L3
  • Gateway por defecto (10.0.0.1)
  • Dispositivo NAT hacia Internet
  • Punto central de interconexión

→ Infraestructura pendiente:
  • No existen aún departamentos (ns-rh, ns-srv, ns-sys, ns-infra)
  • No existen bridges de acceso
  • No existen PCs ni endpoints

===================================================================================
SIGUIENTE PASO — LAB 02: DEPARTAMENTO RH (ACCESS LAYER)
===================================================================================

Objetivo:
→ Implementar el departamento RH como dominio L2 independiente
→ Simular un switch de acceso con múltiples PCs

Componentes a crear:

1) Namespace del departamento
   - ns-rh  (Departamento Recursos Humanos)

2) Enlace CORE ↔ RH (uplink)
   - v-gw-rh   (en CORE-GW)
   - v-rh-gw   (en ns-rh)

3) Direccionamiento del enlace
   - CORE-GW (v-gw-rh): 10.0.0.1/24   [ya existente]
   - ns-rh   (v-rh-gw): sin IP (L2 uplink)

4) Bridge interno del departamento (switch de acceso)
   - br-rh  (dentro de ns-rh)

5) PCs del departamento (endpoints)
   - PC_1-RH : 10.0.0.21/24
   - PC_2-RH : 10.0.0.22/24
   - PC_3-RH : 10.0.0.23/24
   - Gateway: 10.0.0.1

6) Cables virtuales por PC
   - pc-rh1 ↔ ns-rh
     • v-pc1-rh
     • v-rh-pc1

   - pc-rh2 ↔ ns-rh
     • v-pc2-rh
     • v-rh-pc2

   - pc-rh3 ↔ ns-rh
     • v-pc3-rh
     • v-rh-pc3

7) Validaciones
   - Ping entre PCs del departamento
   - Ping al CORE-GW (10.0.0.1)
   - Ping a Internet (8.8.8.8)



EOF
}

#
# Este script construye:
# - Namespace CORE-GW
# - Bridge interno br0 (10.0.0.1/24)
# - Enlace WAN hacia el host
# - NAT funcional hacia Internet
#
# IMPORTANTE:
# - Ejecutar como root
# - Interfaz de salida del host: enp1s0
# ==============================================================================

set -e
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "==[ EJECUTANDO LÓGICA DE RED ]=="

  WAN_IF=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
  echo "→ Interfaz WAN detectada: $WAN_IF"

  echo "==[ 1. CORE-GW: INFRAESTRUCTURA BASE ]=="
  # A. Crear el namespace
  ip netns add CORE-GW 2>/dev/null || true
    # --- PASOS DE IDENTIDAD NUEVOS ---
  # 1. Directorio de configuración persistente
  mkdir -p /etc/netns/CORE-GW
    # 2. Archivo de resolución interno (Hosts)
  cat <<EOF > /etc/netns/CORE-GW/hosts
127.0.0.1       localhost
10.0.0.1        core-gw
EOF
  # 3. Comando de identidad (Hostname en memoria)
  ip netns exec CORE-GW hostname core-gw
  # --------------------------------
  
  ip netns exec CORE-GW ip link set lo up
  ip netns exec CORE-GW ip link add br0 type bridge 2>/dev/null || true
  ip netns exec CORE-GW ip link set br0 up
  ip netns exec CORE-GW ip addr add 10.0.0.1/24 dev br0 2>/dev/null || true

  echo "==[ 2. ENLACE WAN (CORE ↔ HOST) ]=="
  ip link add v-gw-wan type veth peer name v-wan-gw 2>/dev/null || true
  ip link set v-gw-wan netns CORE-GW 2>/dev/null || true
  ip link set v-wan-gw up
  ip netns exec CORE-GW ip link set v-gw-wan up
  ip addr add 172.16.255.1/30 dev v-wan-gw 2>/dev/null || true
  ip netns exec CORE-GW ip addr add 172.16.255.2/30 dev v-gw-wan 2>/dev/null || true
  ip netns exec CORE-GW ip route add default via 172.16.255.1 2>/dev/null || true

  echo "==[ 3. KERNEL & FIREWALL (HOST) ]=="
  update-alternatives --set iptables /usr/sbin/iptables-legacy
  update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
  sysctl -w net.ipv4.ip_forward=1
  iptables -F FORWARD
  iptables -t nat -F POSTROUTING
  # NAT para red WAN y red LAN
  iptables -t nat -A POSTROUTING -s 172.16.255.0/30 -o $WAN_IF -j MASQUERADE
  iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o $WAN_IF -j MASQUERADE
  # Forwarding permisivo para el laboratorio
  iptables -A FORWARD -j ACCEPT
  iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
  # RUTA DE RETORNO CLAVE
  ip route add 10.0.0.0/24 via 172.16.255.2 2>/dev/null || true

  echo "==[ 4. FORWARDING INTERNO (CORE-GW) ]=="
  ip netns exec CORE-GW sysctl -w net.ipv4.ip_forward=1
fi