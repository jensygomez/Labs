#!/bin/bash
# ===================================================================================
# LAB 03: DEPARTAMENTO SYS (ADMIN BASTIÓN)
# Prerequisito: Lab 02 ejecutado y funcionando
# ===================================================================================
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
- CORE-GW: Router/NAT (10.0.0.1) con salida a Internet
- Cada departamento: namespace + bridge propio (aislamiento L2)
- Todos los endpoints: gateway = 10.0.0.1

===================================================================================
ESTADO ACTUAL: LAB 03 COMPLETADO
===================================================================================
✓ CORE-GW funcionando con NAT a Internet
✓ NS-RH creado con bridge br-rh
✓ PCs del departamento RH: 10.0.0.21, 10.0.0.22, 10.0.0.23
✓ NS-SYS creado con bridge br-sys
✓ PC_1-SYS (10.0.0.31) operativa como bastión de administración
✓ Conectividad verificada: PC_1-SYS ↔ RH ↔ Internet OK
✗ Pendientes: NS-SRV, NS-INFRA

===================================================================================
SIGUIENTE PASO — LAB 04: DEPARTAMENTO SRV (SERVICIOS)
===================================================================================

Objetivo:
→ Crear el namespace NS-SRV como departamento de servicios internos
→ Implementar SRV-LDAP (10.0.0.11) como servidor de autenticación central
→ Los usuarios de toda la red se autenticarán contra este servidor

Componentes a crear:

1) Namespace del departamento:
   • NS-SRV

2) Bridge interno:
   • br-srv (switch L2 dentro de NS-SRV)

3) Enlace CORE ↔ SRV:
   • v-gw-srv (en CORE-GW, conectado a br0)
   • v-srv-gw (en NS-SRV, conectado a br-srv)

4) Servidor de autenticación:
   • SRV-LDAP: 10.0.0.11/24
   • Servicio: OpenLDAP (slapd)
   • Estructura base: dc=lab,dc=local
   • Gateway: 10.0.0.1

5) Verificaciones:
   • SRV-LDAP → Gateway (10.0.0.1)
   • SRV-LDAP → PC_1-SYS (10.0.0.31)
   • SRV-LDAP → Internet (8.8.8.8)
   • ldapsearch desde PC_1-SYS → SRV-LDAP OK

===================================================================================
FILOSOFÍA DEL LAB
===================================================================================
- Namespaces = Aislamiento quirúrgico de departamentos
- Bridge     = Switch L2 en memoria (dominio de broadcast independiente)
- Veth pair  = Cable virtual entre namespaces
- Bastión    = Punto único de administración (seguridad y control)
- LDAP       = Directorio centralizado de identidades (quién eres en la red)

===================================================================================
EOF
}


echo "==[ 8. CREACIÓN NAMESPACE NS-SYS ]=="
ip netns add NS-SYS 2>/dev/null || true
ip netns exec NS-SYS ip link set lo up

echo "==[ 9. BRIDGE INTERNO BR-SYS ]=="
ip netns exec NS-SYS ip link add br-sys type bridge 2>/dev/null || true
ip netns exec NS-SYS ip link set br-sys up

echo "==[ 10. ENLACE CORE-GW ↔ NS-SYS ]=="
ip link add v-gw-sys type veth peer name v-sys-gw 2>/dev/null || true
ip link set v-gw-sys netns CORE-GW
ip link set v-sys-gw netns NS-SYS
ip netns exec CORE-GW ip link set v-gw-sys master br0
ip netns exec CORE-GW ip link set v-gw-sys up
ip netns exec NS-SYS ip link set v-sys-gw master br-sys
ip netns exec NS-SYS ip link set v-sys-gw up

echo "==[ 11. DESPLIEGUE PC_1-SYS (BASTIÓN) ]=="
ip netns add PC_1-SYS 2>/dev/null || true
ip link add v-pc1-sys type veth peer name v-sys-pc1 2>/dev/null || true
ip link set v-pc1-sys netns PC_1-SYS
ip link set v-sys-pc1 netns NS-SYS
ip netns exec NS-SYS ip link set v-sys-pc1 master br-sys
ip netns exec NS-SYS ip link set v-sys-pc1 up
ip netns exec PC_1-SYS ip link set lo up
ip netns exec PC_1-SYS ip link set v-pc1-sys up
ip netns exec PC_1-SYS ip addr add 10.0.0.31/24 dev v-pc1-sys
ip netns exec PC_1-SYS ip route add default via 10.0.0.1
echo "   ✔ PC_1-SYS configurada (10.0.0.31)"

echo "==[ 12. VERIFICACIÓN FINAL LAB 03 ]=="
echo -n "→ PC_1-SYS → Gateway (10.0.0.1): "
if ip netns exec PC_1-SYS ping -c1 -W1 10.0.0.1 >/dev/null; then echo "OK"; else echo "FAIL"; fi

echo -n "→ PC_1-SYS → PC_1-RH (10.0.0.21): "
if ip netns exec PC_1-SYS ping -c1 -W1 10.0.0.21 >/dev/null; then echo "OK"; else echo "FAIL"; fi

echo -n "→ PC_1-SYS → Internet (8.8.8.8): "
if ip netns exec PC_1-SYS ping -c1 -W1 8.8.8.8 >/dev/null; then echo "OK"; else echo "FAIL"; fi

