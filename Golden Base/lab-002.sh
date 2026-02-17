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
RESUMEN RÁPIDO
===================================================================================
• CORE-GW: Router/NAT (10.0.0.1) con salida a Internet
• Cada departamento: namespace + bridge propio (aislamiento L2)
• Todos los endpoints: gateway = 10.0.0.1

===================================================================================
ESTADO ACTUAL: LAB 02 COMPLETADO
===================================================================================
✓ CORE-GW funcionando con NAT a Internet
✓ NS-RH creado con bridge br-rh
✓ PCs del departamento RH: 10.0.0.21, 10.0.0.22, 10.0.0.23
✓ Conectividad verificada: PCs ↔ Internet OK
✗ Pendientes: NS-SRV, NS-SYS, NS-INFRA

===================================================================================
SIGUIENTE PASO — LAB 03: DEPARTAMENTO SYS (ADMIN BASTION)
===================================================================================

Objetivo:
→ Crear el namespace NS-SYS como punto de administración central
→ Implementar PC_1-SYS (10.0.0.31) como bastión de gestión
→ Este equipo será el único con acceso SSH a toda la red

Componentes a crear:

1) Namespace del departamento:
   • NS-SYS

2) Bridge interno:
   • br-sys (switch L2 dentro de NS-SYS)

3) Enlace CORE ↔ SYS:
   • v-gw-sys (en CORE-GW, conectado a br0)
   • v-sys-gw (en NS-SYS, conectado a br-sys)

4) Endpoint de administración:
   • PC_1-SYS: 10.0.0.31/24
   • Interfaz: v-pc-sys (en PC) ↔ v-sys-pc (en NS-SYS)
   • Gateway: 10.0.0.1

5) Verificaciones:
   • PC_1-SYS → Gateway (10.0.0.1)
   • PC_1-SYS → PC_1-RH (10.0.0.21)
   • PC_1-SYS → Internet (8.8.8.8)

===================================================================================
FILOSOFÍA DEL LAB
===================================================================================
• Namespaces = Aislamiento quirúrgico de departamentos
• Bridge     = Switch L2 en memoria (dominio de broadcast independiente)
• Veth pair  = Cable virtual entre namespaces
• Bastión    = Punto único de administración (seguridad y control)

===================================================================================
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

echo "==[ 1. CREACIÓN DEL NAMESPACE CORE-GW ]=="
ip netns add CORE-GW || true

# Activar loopback
ip netns exec CORE-GW ip link set lo up

# (Opcional) Hostname interno
ip netns exec CORE-GW hostname CORE-GW


echo "==[ 2. CREACIÓN DEL BRIDGE INTERNO (br0) ]=="
ip netns exec CORE-GW ip link add br0 type bridge || true
ip netns exec CORE-GW ip link set br0 up

# IP del Gateway
ip netns exec CORE-GW ip addr add 10.0.0.1/24 dev br0 || true


echo "==[ 3. CREACIÓN DEL ENLACE WAN (GW ↔ HOST) ]=="
# v-gw-wan  -> dentro de CORE-GW
# v-wan-gw  -> permanece en el host

ip link add v-gw-wan type veth peer name v-wan-gw || true
ip link set v-gw-wan netns CORE-GW

# Levantar interfaces
ip link set v-wan-gw up
ip netns exec CORE-GW ip link set v-gw-wan up


echo "==[ 4. DIRECCIONAMIENTO WAN (172.16.255.0/30) ]=="
# Host
ip addr add 172.16.255.1/30 dev v-wan-gw || true

# CORE-GW
ip netns exec CORE-GW ip addr add 172.16.255.2/30 dev v-gw-wan || true


echo "==[ 5. RUTA POR DEFECTO EN CORE-GW ]=="
ip netns exec CORE-GW ip route add default via 172.16.255.1 || true


echo "==[ 6. HABILITAR FORWARDING EN EL HOST ]=="
sysctl -w net.ipv4.ip_forward=1


echo "==[ 7. CONFIGURACIÓN NAT EN EL HOST ]=="
# Limpio reglas previas (LAB)
iptables -F FORWARD || true
iptables -t nat -F POSTROUTING || true

# NAT hacia Internet
iptables -t nat -A POSTROUTING -s 172.16.255.0/30 -o enp1s0 -j MASQUERADE

# Permitir forward
iptables -A FORWARD -i v-wan-gw -o enp1s0 -j ACCEPT
iptables -A FORWARD -i enp1s0 -o v-wan-gw -m state --state ESTABLISHED,RELATED -j ACCEPT


echo "==[ 8. VERIFICACIÓN BÁSICA ]=="
echo "→ Interfaces en CORE-GW:"
ip netns exec CORE-GW ip -br a

echo
echo "→ Ruta en CORE-GW:"
ip netns exec CORE-GW ip route

echo
echo "→ Prueba de conectividad (ping 8.8.8.8):"
ip netns exec CORE-GW ping -c 2 8.8.8.8

echo
echo "CORE-GW operativo. Paso 1 finalizado."
print_topology
