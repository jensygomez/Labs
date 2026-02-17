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

echo "==[ 5. CREACIÓN DEPARTAMENTO RH (NS-RH) ]=="
ip netns add NS-RH 2>/dev/null || true
ip netns exec NS-RH ip link set lo up
ip netns exec NS-RH ip link add br-rh type bridge 2>/dev/null || true
ip netns exec NS-RH ip link set br-rh up

# Uplink: CORE-GW ↔ NS-RH
ip link add v-gw-rh type veth peer name v-rh-gw 2>/dev/null || true
ip link set v-gw-rh netns CORE-GW
ip link set v-rh-gw netns NS-RH
ip netns exec CORE-GW ip link set v-gw-rh master br0
ip netns exec CORE-GW ip link set v-gw-rh up
ip netns exec NS-RH ip link set v-rh-gw master br-rh
ip netns exec NS-RH ip link set v-rh-gw up

echo "==[ 6. DESPLIEGUE DE PC_1, PC_2, PC_3 EN RH ]=="
for i in 1 2 3; do
    NAME="PC_$i-RH"
    IP="10.0.0.2$i"
    V_PC="v-pc$i-rh"
    V_RH="v-rh-pc$i"
    
    ip netns add $NAME 2>/dev/null || true
    ip link add $V_PC type veth peer name $V_RH 2>/dev/null || true
    ip link set $V_PC netns $NAME
    ip link set $V_RH netns NS-RH
    
    ip netns exec NS-RH ip link set $V_RH master br-rh
    ip netns exec NS-RH ip link set $V_RH up
    
    ip netns exec $NAME ip addr add $IP/24 dev $V_PC
    ip netns exec $NAME ip link set $V_PC up
    ip netns exec $NAME ip link set lo up
    ip netns exec $NAME ip route add default via 10.0.0.1
    echo "   ✔ $NAME configurada ($IP)"
done

echo -e "\n==[ 7. VERIFICACIÓN FINAL ]=="
echo -n "→ PC_1-RH a Internet (8.8.8.8): "
if ip netns exec PC_1-RH ping -c 1 -W 1 8.8.8.8 >/dev/null; then echo "OK"; else echo "FAIL"; fi

echo -n "→ PC_3-RH a PC_1-RH: "
if ip netns exec PC_3-RH ping -c 1 -W 1 10.0.0.21 >/dev/null; then echo "OK"; else echo "FAIL"; fi

