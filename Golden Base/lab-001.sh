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
 │    ns-srv       │   │      ns-rh      │   │      ns-sys     │   │    ns-infra     │
 │  (Servicios)    │   │  (Department)   |   |                 |   |                 |
 |                 |   |    Bridge L2    |   |                 |   |                 |
 |                 |   |   Acces Swicth  │   │     (Admin)     │   │     (Infra)     │
 └────────┬────────┘   └────────┬────────┘   └────────┬────────┘   └────────┬────────┘
          │                     │                     │                     │
  ┌───────┴──────┐       ┌──────┴──────┐       ┌──────┴────┐         ┌──────┴──────┐
  │ serv-ldap    │       │ pc-rh1      │       │ pc-sys1   │         │ pc-dns      │
  │ 10.0.0.11    │       │ 10.0.0.21   │       │ 10.0.0.31 │         │ 10.0.0.2    │
  ├──────────────┤       ├─────────────┤       ├───────────┤         ├─────────────┤
  │ serv-fs      │       │ pc-rh2      │       │           │         │ pc-dhcp     │
  │ 10.0.0.12    │       │ 10.0.0.22   │       │           │         │ 10.0.0.3    │
  └──────────────┘       ├─────────────┤       └───────────┘         └─────────────┘
                         │ pc-rh3      │
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
SIGUIENTE PASO
===================================================================================
→ Crear el departamento RH (ns-rh)
→ Implementar bridge interno (switch de acceso L2)
→ Conectar ns-rh al CORE-GW
→ Crear PCs del departamento (pc-rh1 ... pc-rhN)
→ Asignar IPs del segmento 10.0.0.0/24
→ Gateway: 10.0.0.1
→ Verificar conectividad interna y salida a Internet


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
