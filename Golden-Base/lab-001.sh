#!/bin/bash
# ===================================================================================
# LABORATORIO LINUX PARA CERTIFICACIÓN LFCS/LFCE
# Topología: Infraestructura completa con contenedores Docker
# Versión: 2.0 - Dockerizada y automatizada
# ===================================================================================
print_topology() {
  VERDE='\033[0;32m'
  GRIS='\033[0;37m'
  ROJO='\033[0;31m'
  AMARILLO='\033[1;33m'
  BOLD='\033[1m'
  NC='\033[0m'
  
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

  # AHORA USAMOS echo -e PARA LOS COLORES
  echo -e ""
  echo -e "╔══════════════════════════════════════════╗"
  echo -e "║         LAB 001 — RESUMEN FINAL          ║"
  echo -e "╚══════════════════════════════════════════╝"
  echo -e ""
  echo -e "  ${VERDE}✔ Contenedor${NC}   CORE-GW (ubuntu:24.04)"
  echo -e "  ${VERDE}✔ LAN Bridge${NC}   br0 → 10.0.0.1/24"
  echo -e "  ${VERDE}✔ WAN Link${NC}     172.16.255.2 ↔ 172.16.255.1"
  echo -e "  ${VERDE}✔ NAT${NC}          10.0.0.0/24 + 172.16.255.0/30 → \$WAN_IF"
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


set -e

VERDE='\033[0;32m'
GRIS='\033[0;37m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'


# En engine.sh — función global reutilizable
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
        # Si no tiene "::", usar el comando completo como etiqueta resumida
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




if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "==[ EJECUTANDO LÓGICA DE RED CON DOCKER ]=="

  # 0. Detectar interfaz WAN
  WAN_IF=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
  echo "→ Interfaz WAN detectada: $WAN_IF"

  instalar_con_barra "Instalando Docker" \
    "apt update::apt update -qq" \
    "dependencias::apt install -y -qq ca-certificates curl gnupg lsb-release" \
    "keyrings::install -m 0755 -d /etc/apt/keyrings" \
    "GPG key::curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg" \
    "repositorio Docker::echo 'deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null" \
    "repo update::apt update -qq" \
    "docker-ce::apt install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" \
    "servicio Docker::systemctl start docker && systemctl enable docker"


  # 0.2 Iniciar Docker si no está corriendo
  systemctl start docker || true

  # 0.3 Descargar imagen ubuntu:24.04 si no existe
  if ! docker image inspect ubuntu:24.04 &> /dev/null; then
    echo "Descargando imagen ubuntu:24.04..."
    docker pull ubuntu:24.04
  else
    echo "→ Imagen ubuntu:24.04 ya existe."
  fi

  echo "==[ 1. CORE-GW: INFRAESTRUCTURA BASE CON DOCKER ]=="

  # A. Crear y correr el contenedor (equivalente a 'ip netns add CORE-GW')
  docker run -d --name CORE-GW --hostname core-gw --privileged --network none ubuntu:24.04 sleep infinity 2>/dev/null || true

  # B. Obtener PID y enlazar netns
  CORE_PID=$(docker inspect -f '{{.State.Pid}}' CORE-GW)
  echo "→ PID del contenedor CORE-GW: $CORE_PID"
  mkdir -p /var/run/netns
  ln -sf /proc/$CORE_PID/ns/net /var/run/netns/CORE-GW 2>/dev/null || true

  # --- PASOS DE IDENTIDAD (adaptados) ---
  # Editamos /etc/hosts dentro del contenedor
  docker exec CORE-GW bash -c 'cat <<EOF > /etc/hosts
127.0.0.1       localhost
10.0.0.1        core-gw
EOF' || true
  # Hostname ya está seteado por --hostname, pero confirmamos
  docker exec CORE-GW hostname core-gw || true

# ========================================================
# ========================================================
  instalar_con_barra "Preparando CORE-GW" \
    "apt update::docker exec CORE-GW apt update -qq" \
    "iproute2::docker exec CORE-GW apt install -y -qq iproute2" \
    "vim::docker exec CORE-GW apt install -y -qq vim" \
    "tcpdump::docker exec CORE-GW apt install -y -qq tcpdump"


# ========================================================
# ========================================================






  # Configurar loopback, bridge y IP
  ip netns exec CORE-GW ip link set lo up || true
  ip netns exec CORE-GW ip link add br0 type bridge 2>/dev/null || true
  ip netns exec CORE-GW ip link set br0 up || true
  ip netns exec CORE-GW ip addr add 10.0.0.1/24 dev br0 2>/dev/null || true

  echo "==[ 2. ENLACE WAN (CORE ↔ HOST) ]=="
  ip link add v-gw-wan type veth peer name v-wan-gw 2>/dev/null || true
  ip link set v-gw-wan netns CORE-GW 2>/dev/null || true
  ip link set v-wan-gw up || true
  ip netns exec CORE-GW ip link set v-gw-wan up || true
  ip addr add 172.16.255.1/30 dev v-wan-gw 2>/dev/null || true
  # Forzar la ruta con metric 1000 explícitamente
  ip route add 172.16.255.0/30 dev v-wan-gw metric 1000 2>/dev/null || true
  ip netns exec CORE-GW ip addr add 172.16.255.2/30 dev v-gw-wan 2>/dev/null || true
  # Ruta default (borramos la de Docker si existe y agregamos la nuestra)
  ip netns exec CORE-GW ip route del default 2>/dev/null || true
  ip netns exec CORE-GW ip route add default via 172.16.255.1 2>/dev/null || true

  echo "==[ 3. KERNEL & FIREWALL (HOST) ]=="
  update-alternatives --set iptables /usr/sbin/iptables-legacy || true
  update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy || true
  sysctl -w net.ipv4.ip_forward=1 || true
  iptables -F FORWARD || true
  iptables -t nat -F POSTROUTING || true
  # NAT para red WAN y red LAN
  iptables -t nat -A POSTROUTING -s 172.16.255.0/30 -o $WAN_IF -j MASQUERADE || true
  iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o $WAN_IF -j MASQUERADE || true
  # Forwarding permisivo para el laboratorio
  iptables -A FORWARD -j ACCEPT || true
  iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT || true
  # RUTA DE RETORNO CLAVE
  ip route add 10.0.0.0/24 via 172.16.255.2 metric 1000 2>/dev/null || true

  echo "==[ 4. FORWARDING INTERNO (CORE-GW) ]=="
  ip netns exec CORE-GW sysctl -w net.ipv4.ip_forward=1 || true

  echo "==[ 5. TEST DE CONECTIVIDAD ]=="

  # Host → CORE-GW (WAN link)
  if ping -c 2 -W 2 172.16.255.2 &>/dev/null; then
    echo "✓ Host → CORE-GW (172.16.255.2) OK"
  else
    echo "✗ Host → CORE-GW (172.16.255.2) FALLO"
  fi

  # CORE-GW → Host (WAN link inverso)
  if ip netns exec CORE-GW ping -c 2 -W 2 172.16.255.1 &>/dev/null; then
    echo "✓ CORE-GW → Host (172.16.255.1) OK"
  else
    echo "✗ CORE-GW → Host (172.16.255.1) FALLO"
  fi

  # CORE-GW → Internet (salida NAT)
  if ip netns exec CORE-GW ping -c 2 -W 3 8.8.8.8 &>/dev/null; then
    echo "✓ CORE-GW → Internet (8.8.8.8) OK"
  else
    echo "✗ CORE-GW → Internet (8.8.8.8) FALLO"
  fi

  # Bridge LAN existe y tiene IP
  if ip netns exec CORE-GW ip addr show br0 | grep -q "10.0.0.1"; then
    echo "✓ Bridge LAN (br0 - 10.0.0.1/24) OK"
  else
    echo "✗ Bridge LAN (br0) FALLO"
  fi

  echo "==[ FIN DE TESTS ]=="



fi

