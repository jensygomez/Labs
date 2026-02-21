#!/usr/bin/env bash
# ===================================================================================
# LABORATORIO LINUX PARA CERTIFICACIÓN LFCS/LFCE
# Topología: Infraestructura completa con contenedores Docker
# Versión: 1 - 
# Laboratorio: 001 - Core Gateway y red base
# ===================================================================================

set -Eeuo pipefail

########################################
# VARIABLES GLOBALES
########################################
IMG_BASE="ubuntu:24.04"
IMG_NET="ubuntu-net:24.04"

TMP_BUILDER="img-builder-net"
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
log() { echo -e "\n🔹 $*"; }
ok()  { echo "✅ $*"; }
err() { echo "❌ $*" >&2; exit 1; }

image_exists() {
  docker images --format '{{.Repository}}:{{.Tag}}' | grep -qx "$1"
}

container_exists() {
  docker ps -a --format '{{.Names}}' | grep -qx "$1"
}

container_pid() {
  docker inspect -f '{{.State.Pid}}' "$1"
}

########################################
# FASE 0 — IMAGEN BASE CON RED
########################################
build_image_net() {
  log "FASE 0 — Verificando imagen base $IMG_NET"

  if image_exists "$IMG_NET"; then
    ok "Imagen $IMG_NET ya existe"
    return
  fi

  log "Creando contenedor temporal de build"
  docker run -dit \
    --name "$TMP_BUILDER" \
    --hostname img-builder \
    --privileged \
    "$IMG_BASE"

  log "Instalando herramientas de red"
  docker exec "$TMP_BUILDER" bash -c "
    apt update &&
    apt install -y \
      iproute2 \
      iputils-ping \
      iptables \
      net-tools \
      tcpdump \
      curl &&
    apt clean
  "

  log "Creando imagen $IMG_NET"
  docker commit "$TMP_BUILDER" "$IMG_NET"

  log "Eliminando contenedor temporal"
  docker rm -f "$TMP_BUILDER"

  ok "Imagen base creada correctamente"
}

########################################
# FASE 1 — CORE-GW
########################################
create_core_gw() {
  log "FASE 1 — Creando contenedor CORE-GW"

  if container_exists "$CORE_GW"; then
    ok "CORE-GW ya existe"
    return
  fi

  docker run -dit \
    --name "$CORE_GW" \
    --hostname core-gw \
    --privileged \
    --network none \
    "$IMG_NET"

  ok "CORE-GW creado"
}

########################################
# FASE 2 — VETH HOST ↔ CORE-GW
########################################
setup_veth() {
  log "FASE 2 — Configurando veth WAN"

  if ip link show "$VETH_HOST" &>/dev/null; then
    ok "veth ya existe"
    return
  fi

  ip link add "$VETH_GW" type veth peer name "$VETH_HOST"

  ip link set "$VETH_GW" netns "$(container_pid "$CORE_GW")"

  ip addr add "$HOST_IP" dev "$VETH_HOST"
  ip link set "$VETH_HOST" up

  docker exec "$CORE_GW" ip addr add "$GW_IP" dev "$VETH_GW"
  docker exec "$CORE_GW" ip link set "$VETH_GW" up

  ok "veth configurado"
}

########################################
# FASE 3 — ROUTING + NAT
########################################
setup_routing_nat() {
  log "FASE 3 — Routing y NAT"

  docker exec "$CORE_GW" ip route | grep -q default || \
    docker exec "$CORE_GW" ip route add default via 172.16.255.1

  sysctl -w net.ipv4.ip_forward=1 >/dev/null
  docker exec "$CORE_GW" sysctl -w net.ipv4.ip_forward=1 >/dev/null

  iptables -t nat -C POSTROUTING -s "$GW_NET" -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -s "$GW_NET" -j MASQUERADE

  iptables -C FORWARD -s "$GW_NET" -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -s "$GW_NET" -j ACCEPT

  iptables -C FORWARD -d "$GW_NET" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -d "$GW_NET" -m state --state RELATED,ESTABLISHED -j ACCEPT

  ok "Routing y NAT activos"
}

########################################
# FASE 4 — BRIDGE LAN
########################################
setup_bridge() {
  log "FASE 4 — Bridge LAN br0"

  docker exec "$CORE_GW" ip link show br0 &>/dev/null && {
    ok "br0 ya existe"
    return
  }

  docker exec "$CORE_GW" ip link add br0 type bridge
  docker exec "$CORE_GW" ip addr add "$LAN_IP" dev br0
  docker exec "$CORE_GW" ip link set br0 up

  ok "Bridge br0 creado"
}

########################################
# MAIN
########################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "==[ LAB 001 — CORE-GW | ARQUITECTURA LINUX ]=="

  build_image_net
  create_core_gw
  setup_veth
  setup_routing_nat
  setup_bridge

  echo
  ok "LAB 001 COMPLETADO"
fi


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

