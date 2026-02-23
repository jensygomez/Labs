#!/usr/bin/env bash
# ===================================================================================
# LABORATORIO LINUX PARA CERTIFICACIÓN LFCS/LFCE
# Topología: Infraestructura completa con contenedores Docker
# Versión: 1 - 
# Laboratorio: 001 - Core Gateway y red base
# ===================================================================================

set -Eeuo pipefail

# ── Colores ───────────────────────────────────────────────────────────────────
VERDE='\033[0;32m'; GRIS='\033[0;37m'; ROJO='\033[0;31m'; AMARILLO='\033[1;33m'
AZUL='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BOLD='\033[1m'; NC='\033[0m'
OK="✅"; ERR="❌"; INFO="🔹"

########################################
# VARIABLES GLOBALES
########################################
IMG_NET="ubuntu-net:24.04"
CORE_GW="CORE-GW"

HOST_IP="172.16.255.1/30"
GW_IP="172.16.255.2/30"
GW_NET="172.16.255.0/30"
LAN_IP="10.0.0.1/24"

VETH_GW="v-gw-wan"
VETH_HOST="v-host-gw"

########################################
# UTILIDADES
########################################
log() { echo -e "\n$INFO $*"; }
ok()  { echo "$OK $*"; }
err() { echo "$ERR $*" >&2; exit 1; }

image_exists() { docker images --format '{{.Repository}}:{{.Tag}}' | grep -qx "$1"; }
container_exists() { docker ps -a --format '{{.Names}}' | grep -qx "$1"; }
container_pid() { docker inspect -f '{{.State.Pid}}' "$1"; }

########################################
# FASE 0 — CONSTRUCCIÓN CON DOCKERFILE
########################################
build_image_net() {
  log "FASE 0 — Verificando imagen $IMG_NET"

  if image_exists "$IMG_NET"; then
    ok "Imagen $IMG_NET ya existe. Saltando build."
    return
  fi

  # 1. Cambiamos la validación para que busque un nivel arriba (../)
  if [ ! -f ../Dockerfile ]; then
    err "No se encuentra el archivo 'Dockerfile' en ../ (Directorio raíz)"
  fi

  log "Construyendo imagen $IMG_NET desde ../Dockerfile..."
  
  # 2. Le indicamos a docker build que use el archivo de la carpeta superior
  # pero que use el contexto actual
  docker build -t "$IMG_NET" -f ../Dockerfile ..
  
  ok "Imagen base creada correctamente"
}

########################################
# FASE 1 — CORE-GW (Nombre y Hostname idénticos)
########################################
create_core_gw() {
  log "FASE 1 — Creando contenedor $CORE_GW"

  if container_exists "$CORE_GW"; then
    ok "$CORE_GW ya existe"
    return
  fi

  # Usamos la variable CORE_GW para ambos parámetros
  docker run -dit \
    --name "$CORE_GW" \
    --hostname "$CORE_GW" \
    --privileged \
    --network none \
    "$IMG_NET"

  ok "Contenedor '$CORE_GW' creado con hostname '$(docker exec $CORE_GW hostname)'"
}

########################################
# FASE 2 — REDES (VETH, ROUTING, BRIDGE)
########################################
# (Mantenemos tu lógica de red original que ya funciona muy bien)
setup_veth() {
  log "FASE 2 — Configurando veth WAN"
  if ip link show "$VETH_HOST" &>/dev/null; then
    ok "veth ya existe"; return
  fi

  ip link add "$VETH_GW" type veth peer name "$VETH_HOST"
  ip link set "$VETH_GW" netns "$(container_pid "$CORE_GW")"
  ip addr add "$HOST_IP" dev "$VETH_HOST"
  ip link set "$VETH_HOST" up
  docker exec "$CORE_GW" ip addr add "$GW_IP" dev "$VETH_GW"
  docker exec "$CORE_GW" ip link set "$VETH_GW" up
  ok "Conectividad veth Host <-> GW establecida"
}

setup_routing_nat() {
  log "FASE 3 — Routing y NAT"
  docker exec "$CORE_GW" ip route replace default via 172.16.255.1
  sysctl -w net.ipv4.ip_forward=1 >/dev/null
  docker exec "$CORE_GW" sysctl -w net.ipv4.ip_forward=1 >/dev/null

  iptables -t nat -A POSTROUTING -s "$GW_NET" -j MASQUERADE 2>/dev/null || true
  iptables -A FORWARD -s "$GW_NET" -j ACCEPT 2>/dev/null || true
  ok "Routing configurado"
}

setup_bridge() {
  log "FASE 4 — Bridge LAN br0"
  if docker exec "$CORE_GW" ip link show br0 &>/dev/null; then
    ok "br0 ya existe"; return
  fi
  docker exec "$CORE_GW" ip link add br0 type bridge
  docker exec "$CORE_GW" ip addr add "$LAN_IP" dev br0
  docker exec "$CORE_GW" ip link set br0 up
  ok "Bridge br0 listo para recibir otros laboratorios"
}

########################################
# MAIN
########################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo -e "${AZUL}${BOLD}==[ LAB 001 — CORE-GW | INFRAESTRUCTURA ]==${NC}"
  
  build_image_net
  create_core_gw
  setup_veth
  setup_routing_nat
  setup_bridge

  echo -e "\n${VERDE}${BOLD}LAB 001 COMPLETADO CON ÉXITO${NC}"
fi


# ===================================================================================
# FUNCIÓN: print_topology - Muestra la topología del laboratorio
# ===================================================================================
print_topology() {
# ── Colores ───────────────────────────────────────────────────────────────────
  local VERDE='\033[0;32m'
  local GRIS='\033[0;37m'
  local ROJO='\033[0;31m'
  local AMARILLO='\033[1;33m'
  local AZUL='\033[0;34m'
  local CYAN='\033[0;36m'
  local NC='\033[0m'

  # Dibujo de la Topología
  cat <<EOF

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

  echo -e ""
  echo -e "╔══════════════════════════════════════════╗"
  echo -e "║         LAB 001 — RESUMEN FINAL          ║"
  echo -e "╚══════════════════════════════════════════╝"
  echo -e ""
  echo -e "  ${VERDE}✔ Docker Base${NC}  $IMG_NET (lista para RH/INFRA/SERV/SYS)${NC}"
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

