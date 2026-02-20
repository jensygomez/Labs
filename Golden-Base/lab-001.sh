#!/bin/bash
# ===================================================================================
# LABORATORIO LINUX PARA CERTIFICACIÓN LFCS/LFCE
# Topología: Infraestructura completa con contenedores Docker
# Versión: 2.0 - Dockerizada y automatizada
# Laboratorio: 001 - Core Gateway y red base
# ===================================================================================

# ── Configuración inicial ─────────────────────────────────────────────────────
set -e  # Salir si hay error crítico
set -o pipefail

# ── Verificar ejecución como root ─────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then 
    echo "Este script debe ejecutarse como root"
    exit 1
fi

# ── Colores globales ──────────────────────────────────────────────────────────
VERDE='\033[0;32m'
GRIS='\033[0;37m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ===================================================================================
# FUNCIÓN: print_topology - Muestra la topología del laboratorio
# ===================================================================================
print_topology() {
  cat <<'EOF'
===================================================================================
TOPOLOGÍA DISTRIBUIDA – LAB DE ARQUITECTURA LINUX (DOCKERIZADO)
===================================================================================

                          ┌─────────────────────────────────────┐
                          │         INTERNET (8.8.8.8)          │
                          └───────────────┬─────────────────────┘
                                          │
                          ┌───────────────┴─────────────────────┐
                          │            HOST (tu PC/VM)           │
                          │       172.16.255.1/30 (v-wan-gw)    │
                          └───────────────┬─────────────────────┘
                                          │
                                          │ veth pair
                                          │
                      ┌───────────────────┴───────────────────────────┐
                      │           CORE-GW (contenedor Docker)         │
                      │       ┌─────────────────────────────┐         │
                      │       │  br0: 10.0.0.1/24           │         │
                      │       │  v-gw-wan: 172.16.255.2/30  │         │
                      │       └─────────────────────────────┘         │
                      └───────────────────┬───────────────────────────┘
                                          │       
           ┌───────────────────┌──────────┘──────────┌──────────────────────┐
           │                   │                     │                      │
  ┌────────┴────────┐ ┌────────┴─────────┐  ┌────────┴────────┐    ┌────────┴────────┐
  │    NS-SRV       │ │      NS-RH       │  │      NS-SYS     │    │     NS-INFRA    │
  │ (contenedor)    │ │ (contenedor)     │  │ (contenedor)    │    │ (contenedor)    │
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
• Contenedores Docker     = Aislamiento + filesystem propio
• Bridge                  = Switch L2 dentro del contenedor
• Veth                    = Cable virtual entre contenedor y host
• ip netns exec           = Manipulación de red como en namespaces clásicos
• Kernel del host         = Única fuente de verdad (forwarding, NAT, iptables)
EOF

  # Usar variables globales de color
  echo -e ""
  echo -e "╔══════════════════════════════════════════╗"
  echo -e "║         LAB 001 — RESUMEN FINAL          ║"
  echo -e "╚══════════════════════════════════════════╝"
  echo -e ""
  echo -e "  ${VERDE}✔ Contenedor${NC}   CORE-GW (ubuntu:24.04)"
  echo -e "  ${VERDE}✔ LAN Bridge${NC}   br0 → 10.0.0.1/24"
  echo -e "  ${VERDE}✔ WAN Link${NC}     172.16.255.2 ↔ 172.16.255.1"
  echo -e "  ${VERDE}✔ NAT${NC}          10.0.0.0/24 + 172.16.255.0/30 → ${WAN_IF:-INTERNET}"
  echo -e "  ${VERDE}✔ Forwarding${NC}   HOST + CORE-GW habilitados"
  echo -e ""
  echo -e "  Pendiente:"
  echo -e "  ${GRIS}  ░ Contenedores de departamentos${NC}"
  echo -e "  ${GRIS}  ░ Bridges br-inf br-srv br-rh br-sys${NC}"
  echo -e "  ${GRIS}  ░ Servicios DNS DHCP LDAP FS${NC}"
  echo -e ""

  echo -e ""
  echo -e "╔══════════════════════════════════════════╗"
  echo -e "║       PRÓXIMO — LAB 002: DEPT. RH        ║"
  echo -e "╚══════════════════════════════════════════╝"
  echo -e ""
  echo -e "  Objetivo: Implementar RH como dominio L2 independiente"
  echo -e ""
  echo -e "  Por crear:"
  echo -e "  ${GRIS}  ░ Contenedor   NS-RH${NC}"
  echo -e "  ${GRIS}  ░ Uplink       v-gw-rh (br0) ↔ v-rh-gw (NS-RH)${NC}"
  echo -e "  ${GRIS}  ░ Bridge       br-rh (switch de acceso)${NC}"
  echo -e "  ${GRIS}  ░ PCs          PC1→10.0.0.21  PC2→10.0.0.22  PC3→10.0.0.23${NC}"
  echo -e "  ${GRIS}  ░ Veth pairs   v-pc1-rh↔v-rh-pc1  v-pc2-rh↔v-rh-pc2  v-pc3-rh↔v-rh-pc3${NC}"
  echo -e ""
  echo -e "  Validaciones esperadas:"
  echo -e "  ${GRIS}  ░ Ping entre PCs del departamento (L2)${NC}"
  echo -e "  ${GRIS}  ░ Ping PCs → CORE-GW (10.0.0.1)${NC}"
  echo -e "  ${GRIS}  ░ Ping PCs → Internet (8.8.8.8)${NC}"
  echo -e ""
}

# ===================================================================================
# FUNCIÓN: instalar_con_barra - Barra de progreso para instalaciones
# ===================================================================================
instalar_con_barra() {
    # Uso:
    # instalar_con_barra "Título opcional" cmd1 cmd2 cmd3 ...
    # Cada cmd es un string con el comando completo a ejecutar

    local titulo="$1"
    shift
    local tareas=("$@")
    local total=${#tareas[@]}

    [[ -n "$titulo" ]] && echo -e "→ ${titulo}"
    echo ""

    for i in "${!tareas[@]}"; do
        local tarea="${tareas[$i]}"

        # Extraer etiqueta: si el comando tiene formato "etiqueta::comando", separar
        if [[ "$tarea" == *"::"* ]]; then
            local etiqueta="${tarea%%::*}"
            local cmd="${tarea##*::}"
        else
            local etiqueta="$tarea"
            local cmd="$tarea"
        fi

        # Ejecutar el comando
        eval "$cmd" > /dev/null 2>&1 || true

        # Calcular barra
        local porcentaje=$(( (i + 1) * 100 / total ))
        local bloques_llenos=$(( (i + 1) * 20 / total ))
        local bloques_vacios=$(( 20 - bloques_llenos ))
        local barra_llena="" barra_vacia=""
        for ((b=0; b<bloques_llenos; b++)); do barra_llena+="██"; done
        for ((b=0; b<bloques_vacios; b++)); do barra_vacia+="░░"; done

        echo -ne "\r  ${VERDE}${BOLD}[${barra_llena}${GRIS}${barra_vacia}${VERDE}]${NC} ${BOLD}${porcentaje}%${NC} → ${etiqueta}          "
    done

    echo -e "\n"
    echo -e "  ${VERDE}${BOLD}✔ ${titulo} completado — ${total} pasos ejecutados.${NC}"
    echo ""
}

# ===================================================================================
# FUNCIÓN: cleanup_on_error - Limpieza en caso de error
# ===================================================================================
cleanup_on_error() {
    echo -e "\n${ROJO}╔══════════════════════════════════════════╗${NC}"
    echo -e "${ROJO}║         ERROR EN LA EJECUCIÓN           ║${NC}"
    echo -e "${ROJO}╚══════════════════════════════════════════╝${NC}"
    echo -e "${AMARILLO}Limpiando recursos creados...${NC}"
    
    # Eliminar contenedor si existe
    docker rm -f CORE-GW 2>/dev/null || true
    
    # Eliminar symlink de netns
    rm -f /var/run/netns/CORE-GW 2>/dev/null || true
    
    # Eliminar interfaces veth
    ip link del v-gw-wan 2>/dev/null || true
    ip link del v-wan-gw 2>/dev/null || true
    
    echo -e "${VERDE}✔ Limpieza completada${NC}"
    exit 1
}

# ===================================================================================
# FUNCIÓN: mostrar_ayuda_acceso - Muestra cómo acceder a los namespaces
# ===================================================================================
mostrar_ayuda_acceso() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      ACCESO A LOS NAMESPACES            ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Para acceder al CORE-GW:${NC}"
    echo -e "  ${GRIS}  ip netns exec CORE-GW bash${NC}"
    echo -e "  ${GRIS}  ip netns exec CORE-GW ip addr show${NC}"
    echo -e "  ${GRIS}  ip netns exec CORE-GW ping 8.8.8.8${NC}"
    echo ""
    echo -e "  ${BOLD}Para ver todos los namespaces:${NC}"
    echo -e "  ${GRIS}  ip netns list${NC}"
    echo ""
}

# ===================================================================================
# EJECUCIÓN PRINCIPAL
# ===================================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  
  # Trampa para errores
  trap cleanup_on_error ERR
  
  echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║    LAB 001 - CORE-GW Y RED BASE         ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
  echo ""

  # 0. Detectar interfaz WAN
  WAN_IF=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}')
  if [ -z "$WAN_IF" ]; then
      echo -e "${AMARILLO}⚠ No se pudo detectar interfaz WAN, usando eth0 como fallback${NC}"
      WAN_IF="eth0"
  fi
  echo -e "→ Interfaz WAN detectada: ${BOLD}$WAN_IF${NC}"
  echo ""

  # 1. Instalación de Docker
  instalar_con_barra "Instalando Docker" \
    "apt update::apt update -qq" \
    "dependencias::apt install -y -qq ca-certificates curl gnupg lsb-release" \
    "keyrings::install -m 0755 -d /etc/apt/keyrings" \
    "GPG key::curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg" \
    "repositorio Docker::echo 'deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null" \
    "repo update::apt update -qq" \
    "docker-ce::apt install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" \
    "servicio Docker::systemctl start docker && systemctl enable docker"

  # 2. Iniciar Docker y verificar
  systemctl start docker 2>/dev/null || true
  echo -e "${VERDE}✓ Docker service verificando${NC}"

  # 3. Descargar imagen ubuntu:24.04 si no existe
  if ! docker image inspect ubuntu:24.04 &> /dev/null; then
    echo -e "→ Descargando imagen ${BOLD}ubuntu:24.04${NC}..."
    docker pull ubuntu:24.04 > /dev/null
    echo -e "${VERDE}✓ Imagen descargada${NC}"
  else
    echo -e "→ Imagen ${BOLD}ubuntu:24.04${NC} ya existe."
  fi

  echo ""
  echo -e "${CYAN}==[ 1. CORE-GW: INFRAESTRUCTURA BASE CON DOCKER ]==${NC}"

  # 4. Crear y correr el contenedor
  docker rm -f CORE-GW 2>/dev/null || true
  docker run -d --name CORE-GW --hostname core-gw --privileged --network none ubuntu:24.04 sleep infinity > /dev/null
  echo -e "${VERDE}✓ Contenedor CORE-GW creado${NC}"

  # 5. Obtener PID y enlazar netns
  CORE_PID=$(docker inspect -f '{{.State.Pid}}' CORE-GW)
  echo -e "→ PID del contenedor CORE-GW: ${BOLD}$CORE_PID${NC}"
  mkdir -p /var/run/netns
  ln -sf /proc/$CORE_PID/ns/net /var/run/netns/CORE-GW 2>/dev/null || true
  echo -e "${VERDE}✓ Namespace enlazado en /var/run/netns/CORE-GW${NC}"

  # 6. Configurar /etc/hosts
  docker exec CORE-GW bash -c 'cat <<EOF > /etc/hosts
127.0.0.1       localhost
10.0.0.1        core-gw
EOF' || true
  docker exec CORE-GW hostname core-gw || true
  echo -e "${VERDE}✓ Configuración de identidad completada${NC}"

  # 7. Instalar paquetes básicos en CORE-GW
  instalar_con_barra "Preparando CORE-GW" \
    "apt update::docker exec CORE-GW apt update -qq" \
    "iproute2::docker exec CORE-GW apt install -y -qq iproute2" \
    "ping::docker exec CORE-GW apt install -y -qq iputils-ping" \
    "vim::docker exec CORE-GW apt install -y -qq vim" \
    "tcpdump::docker exec CORE-GW apt install -y -qq tcpdump" \
    "dnsutils::docker exec CORE-GW apt install -y -qq dnsutils" \
    "curl::docker exec CORE-GW apt install -y -qq curl"

  # 8. Configurar red interna del contenedor
  echo -e "${CYAN}==[ 2. CONFIGURACIÓN DE RED INTERNA ]==${NC}"
  
  ip netns exec CORE-GW ip link set lo up
  ip netns exec CORE-GW ip link add br0 type bridge 2>/dev/null || true
  ip netns exec CORE-GW ip link set br0 up
  ip netns exec CORE-GW ip addr add 10.0.0.1/24 dev br0 2>/dev/null || true
  echo -e "${VERDE}✓ Bridge br0 creado con IP 10.0.0.1/24${NC}"

  echo -e "${CYAN}==[ 3. ENLACE WAN (CORE ↔ HOST) ]==${NC}"
  
  # Limpiar interfaces existentes
  ip link del v-gw-wan 2>/dev/null || true
  ip link del v-wan-gw 2>/dev/null || true
  
  # Crear veth pair
  ip link add v-gw-wan type veth peer name v-wan-gw
  ip link set v-gw-wan netns CORE-GW
  ip link set v-wan-gw up
  ip netns exec CORE-GW ip link set v-gw-wan up
  
  # Asignar IPs
  ip addr add 172.16.255.1/30 dev v-wan-gw 2>/dev/null || true
  ip netns exec CORE-GW ip addr add 172.16.255.2/30 dev v-gw-wan 2>/dev/null || true
  
  # Configurar rutas
  ip route add 172.16.255.0/30 dev v-wan-gw metric 1000 2>/dev/null || true
  ip netns exec CORE-GW ip route del default 2>/dev/null || true
  ip netns exec CORE-GW ip route add default via 172.16.255.1
  
  echo -e "${VERDE}✓ Enlace WAN configurado: 172.16.255.1 (host) ↔ 172.16.255.2 (CORE)${NC}"

  echo -e "${CYAN}==[ 4. CONFIGURACIÓN KERNEL & FIREWALL ]==${NC}"
  
  # Configurar iptables legacy si es necesario
  if command -v update-alternatives &> /dev/null; then
    update-alternatives --set iptables /usr/sbin/iptables-legacy 2>/dev/null || true
    update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy 2>/dev/null || true
  fi
  
  # Habilitar forwarding
  sysctl -w net.ipv4.ip_forward=1 > /dev/null
  ip netns exec CORE-GW sysctl -w net.ipv4.ip_forward=1 > /dev/null
  
  # Limpiar reglas existentes del laboratorio
  iptables -D FORWARD -s 172.16.255.0/30 -j ACCEPT 2>/dev/null || true
  iptables -D FORWARD -d 172.16.255.0/30 -j ACCEPT 2>/dev/null || true
  iptables -t nat -D POSTROUTING -s 172.16.255.0/30 -o $WAN_IF -j MASQUERADE 2>/dev/null || true
  iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o $WAN_IF -j MASQUERADE 2>/dev/null || true
  
  # Configurar NAT
  iptables -t nat -A POSTROUTING -s 172.16.255.0/30 -o $WAN_IF -j MASQUERADE
  iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o $WAN_IF -j MASQUERADE
  
  # Forwarding permisivo
  iptables -A FORWARD -s 172.16.255.0/30 -j ACCEPT
  iptables -A FORWARD -d 172.16.255.0/30 -j ACCEPT
  iptables -A FORWARD -s 10.0.0.0/24 -j ACCEPT
  iptables -A FORWARD -d 10.0.0.0/24 -j ACCEPT
  iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
  
  # Ruta de retorno
  ip route add 10.0.0.0/24 via 172.16.255.2 metric 1000 2>/dev/null || true
  
  echo -e "${VERDE}✓ Firewall y rutas configurados${NC}"

  echo -e "${CYAN}==[ 5. TEST DE CONECTIVIDAD ]==${NC}"
  echo ""

  # Tests de conectividad
  TEST_EXITOS=0
  TEST_FALLOS=0

  # Host → CORE-GW
  if ping -c 2 -W 2 172.16.255.2 &>/dev/null; then
    echo -e "  ${VERDE}✓${NC} Host → CORE-GW (172.16.255.2) ${VERDE}OK${NC}"
    ((TEST_EXITOS++))
  else
    echo -e "  ${ROJO}✗${NC} Host → CORE-GW (172.16.255.2) ${ROJO}FALLO${NC}"
    ((TEST_FALLOS++))
  fi

  # CORE-GW → Host
  if ip netns exec CORE-GW ping -c 2 -W 2 172.16.255.1 &>/dev/null; then
    echo -e "  ${VERDE}✓${NC} CORE-GW → Host (172.16.255.1) ${VERDE}OK${NC}"
    ((TEST_EXITOS++))
  else
    echo -e "  ${ROJO}✗${NC} CORE-GW → Host (172.16.255.1) ${ROJO}FALLO${NC}"
    ((TEST_FALLOS++))
  fi

  # CORE-GW → Internet
  if ip netns exec CORE-GW ping -c 2 -W 3 8.8.8.8 &>/dev/null; then
    echo -e "  ${VERDE}✓${NC} CORE-GW → Internet (8.8.8.8) ${VERDE}OK${NC}"
    ((TEST_EXITOS++))
  else
    echo -e "  ${ROJO}✗${NC} CORE-GW → Internet (8.8.8.8) ${ROJO}FALLO${NC}"
    ((TEST_FALLOS++))
  fi

  # Bridge LAN
  if ip netns exec CORE-GW ip addr show br0 | grep -q "10.0.0.1"; then
    echo -e "  ${VERDE}✓${NC} Bridge LAN (br0 - 10.0.0.1/24) ${VERDE}OK${NC}"
    ((TEST_EXITOS++))
  else
    echo -e "  ${ROJO}✗${NC} Bridge LAN (br0) ${ROJO}FALLO${NC}"
    ((TEST_FALLOS++))
  fi

  # DNS resolution desde CORE-GW
  if ip netns exec CORE-GW nslookup google.com 8.8.8.8 &>/dev/null; then
    echo -e "  ${VERDE}✓${NC} DNS resolution (8.8.8.8) ${VERDE}OK${NC}"
    ((TEST_EXITOS++))
  else
    echo -e "  ${AMARILLO}⚠${NC} DNS resolution (8.8.8.8) ${AMARILLO}FALLO (opcional)${NC}"
  fi

  echo ""
  echo -e "  ${BOLD}Resumen:${NC} ${VERDE}$TEST_EXITOS exitosos${NC}, ${ROJO}$TEST_FALLOS fallos${NC}"
  echo ""

  if [ $TEST_FALLOS -eq 0 ]; then
    echo -e "${VERDE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${VERDE}║    LAB 001 COMPLETADO EXITOSAMENTE     ║${NC}"
    echo -e "${VERDE}╚══════════════════════════════════════════╝${NC}"
  else
    echo -e "${AMARILLO}╔══════════════════════════════════════════╗${NC}"
    echo -e "${AMARILLO}║    LAB 001 COMPLETADO CON ADVERTENCIAS ║${NC}"
    echo -e "${AMARILLO}╚══════════════════════════════════════════╝${NC}"
  fi

  # Mostrar topología
  print_topology
  
  # Mostrar ayuda de acceso
  mostrar_ayuda_acceso

  # Desactivar trampa de error (ya terminó)
  trap - ERR
  
  echo -e "${GRIS}───────────────────────────────────────────────────────${NC}"
  echo -e "${GRIS}Para continuar, ejecuta: engine.sh y selecciona opción 1${NC}"
  echo ""
fi