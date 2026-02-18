
#!/bin/bash
# Golden-Base/lab-004.sh
# ===================================================================================
# LAB 04: DEPARTAMENTO SRV (SERVIDORES)
# Prerequisito: Lab 03 ejecutado y funcionando
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
- CORE-GW: Router/NAT (10.0.0.1) con salida a Internet.
- Cada departamento: Namespace + bridge propio (aislamiento L2 quirúrgico).
- Endpoints: Todos apuntan al Gateway 10.0.0.1.
- Identidad: Resolución local vía /etc/hosts en cada namespace.

===================================================================================
ESTADO ACTUAL: LAB 04 COMPLETADO
===================================================================================
✓ CORE-GW: Funcionando con NAT y ruteo inter-departamental.
✓ NS-RH (Recursos Humanos): Bridge br-rh activo con 3 PCs (10.0.0.21-23).
✓ NS-SYS (Administración): Bridge br-sys con PC_1-SYS (10.0.0.31) como Bastión.
✓ NS-SRV (Servicios): * Namespace de departamento y Bridge br-srv creados.
✓ Servidor SRV-LDAP (10.0.0.11) desplegado y conectado.
✓ Conectividad: Verificada desde SRV hacia Gateway, Internet y otros departamentos (RH).

===================================================================================
SIGUIENTE PASO — LAB 05: SERVICIOS DE IDENTIDAD (OPENLDAP)
===================================================================================

Objetivo:
→ Transformar el namespace SRV-LDAP de un nodo de red vacío a un Servidor de Directorio Operativo.
→ Configurar la base de datos de identidades para el dominio lab.local.
→ Permitir que otros departamentos (como el PC_1-SYS) puedan realizar consultas de usuarios.

Componentes a configurar (Lógica Interna):

1) Instalación del Stack:
    • slapd (el demonio de OpenLDAP).
    • ldap-utils (herramientas de gestión).

2) Configuración del Directorio:
    • Base DN: dc=lab,dc=local.
    • Creación de Unidades Organizativas (OU): ou=People y ou=Groups.
    • Creación de un usuario de prueba para validar la autenticación.

3) Seguridad y Acceso:
    • Configurar el listener para que acepte conexiones en la IP 10.0.0.11.
    • Ajustar el Firewall interno del namespace si fuera necesario.

4) Verificaciones de "Vida":
    • Desde SRV-LDAP: ldapsearch -x -b "dc=lab,dc=local" (Consulta local).
    • Desde PC_1-SYS: ldapsearch -h 10.0.0.11 -x -b "dc=lab,dc=local" (Consulta remota).




EOF
}
# --- 2. FUNCIÓN DE EJECUCIÓN (Toda la lógica de red: Departamento SRV) ---

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "==[ EJECUTANDO LÓGICA DE RED: DEPARTAMENTO SRV ]=="

    # --- PASO 12 & 13: CREACIÓN DE INFRAESTRUCTURA SRV (Servicios) ---
    echo "==[ 12. CREACIÓN NAMESPACE NS-SRV ]=="
    ip netns add NS-SRV 2>/dev/null || true
    ip netns exec NS-SRV ip link set lo up

    echo "==[ 13. BRIDGE INTERNO BR-SRV ]=="
    # Como aprendimos en el terminal, creamos el bridge directamente dentro
    ip netns exec NS-SRV ip link add br-srv type bridge 2>/dev/null || true
    ip netns exec NS-SRV ip link set br-srv up

    # --- PASO 14: ENLACE CORE-GW ↔ NS-SRV ---
    echo "==[ 14. ENLACE CORE-GW ↔ NS-SRV ]=="
    ip link del v-gw-srv 2>/dev/null || true
    ip link add v-gw-srv type veth peer name v-srv-gw 2>/dev/null || true
    
    ip link set v-gw-srv netns CORE-GW
    ip link set v-srv-gw netns NS-SRV
    
    ip netns exec CORE-GW ip link set v-gw-srv master br0
    ip netns exec CORE-GW ip link set v-gw-srv up
    ip netns exec NS-SRV ip link set v-srv-gw master br-srv
    ip netns exec NS-SRV ip link set v-srv-gw up

    # --- PASO 15: DESPLIEGUE SRV-LDAP (SERVIDOR IDENTIDAD) ---
    echo "==[ 15. DESPLIEGUE SRV-LDAP ]=="
    SERVER_NAME="SRV-LDAP"
    HOSTNAME_SRV="srv-ldap"
    IP_SRV="10.0.0.11"

    # 1. Crear namespace del servidor
    ip netns add $SERVER_NAME 2>/dev/null || true

    # 2. Configuración de Identidad (hosts)
    mkdir -p /etc/netns/$SERVER_NAME
    cat <<EOF > /etc/netns/$SERVER_NAME/hosts
127.0.0.1       localhost $HOSTNAME_SRV
$IP_SRV         $HOSTNAME_SRV.lab.local $HOSTNAME_SRV
10.0.0.1        core-gw
10.0.0.31       pc-1-sys
EOF

    # Aplicar hostname de forma estanca
    ip netns exec $SERVER_NAME unshare -u hostname $HOSTNAME_SRV
    ip netns exec $SERVER_NAME mount --bind /etc/netns/$SERVER_NAME/hosts /etc/hosts 2>/dev/null || true

    # 3. Conectividad (Cableado virtual al bridge del departamento)
    ip link del v-ldap-srv 2>/dev/null || true
    ip link add v-ldap-srv type veth peer name v-srv-ldap 2>/dev/null || true
    
    ip link set v-ldap-srv netns $SERVER_NAME
    ip link set v-srv-ldap netns NS-SRV
    
    ip netns exec NS-SRV ip link set v-srv-ldap master br-srv
    ip netns exec NS-SRV ip link set v-srv-ldap up
    
    # 4. Configuración IP y Rutas
    ip netns exec $SERVER_NAME ip link set lo up
    ip netns exec $SERVER_NAME ip link set v-ldap-srv up
    ip netns exec $SERVER_NAME ip addr add $IP_SRV/24 dev v-ldap-srv
    ip netns exec $SERVER_NAME ip route add default via 10.0.0.1
    
    echo "   ✔ $SERVER_NAME configurado ($IP_SRV) con éxito"

    # --- VERIFICACIONES FINALES ---
    echo "==[ 16. VERIFICACIÓN DE CONECTIVIDAD ]=="
    
    echo -n "→ SRV-LDAP → Gateway (10.0.0.1): "
    if ip netns exec SRV-LDAP ping -c1 -W1 10.0.0.1 >/dev/null; then echo "OK"; else echo "FAIL"; fi

    echo -n "→ SRV-LDAP → Internet (8.8.8.8): "
    if ip netns exec SRV-LDAP ping -c1 -W1 8.8.8.8 >/dev/null; then echo "OK"; else echo "FAIL"; fi

    echo -n "→ SRV-LDAP → PC_1-RH (10.0.0.21): "
    if ip netns exec SRV-LDAP ping -c1 -W1 10.0.0.21 >/dev/null; then echo "OK"; else echo "FAIL"; fi
fi