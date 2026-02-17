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
                          │           INTERNET (NAT)            │
                          └───────────────┬─────────────────────┘
                                          │
          ┌───────────────────────────────┴─────────────────────────────────┐
          │                            CORE-GW                              │
          │                  (Router + NAT + Firewall)                      │
          │                        br0: 10.0.0.1/24                         │
          └───────────────────────────────┬─────────────────────────────────┘
                                          |
          ┌─────────────────────┬─────────────────────┬─────────────────────┐
          │                     │                     │                     │
 ┌────────┴────────┐   ┌────────┴────────┐   ┌────────┴────────┐   ┌────────┴────────┐
 │    ns-srv       │   │      NS-RH      │   │      ns-sys     │   │    ns-infra     │
 │  (Servicios)    │   │  (Department)   |   |                 |   |                 |
 |                 |   |    Bridge L2    |   |                 |   |                 |
 |                 |   |   Acces Swicth  │   │     (Admin)     │   │     (Infra)     │
 └────────┬────────┘   └────────┬────────┘   └────────┬────────┘   └────────┬────────┘
          │                     │                     │                     │
  ┌───────┴──────┐       ┌──────┴──────┐       ┌──────┴────┐         ┌──────┴──────┐
  │ serv-ldap    │       │ PC_1-RH     │       │ pc-sys1   │         │ pc-dns      │
  │ 10.0.0.11    │       │ 10.0.0.21   │       │ 10.0.0.31 │         │ 10.0.0.2    │
  ├──────────────┤       ├─────────────┤       ├───────────┤         ├─────────────┤
  │ serv-fs      │       │ PC_2-RH     │       │           │         │ pc-dhcp     │
  │ 10.0.0.12    │       │ 10.0.0.22   │       │           │         │ 10.0.0.3    │
  └──────────────┘       ├─────────────┤       └───────────┘         └─────────────┘
                         │ PC_3-RH     │
                         │ 10.0.0.23   │
                         └─────────────┘

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
