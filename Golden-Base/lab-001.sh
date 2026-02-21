#!/usr/bin/env bash
# ===================================================================================
# LABORATORIO LINUX PARA CERTIFICACIÓN LFCS/LFCE
# Topología: Infraestructura completa con contenedores Docker
# Versión: 1 - 
# Laboratorio: 001 - Core Gateway y red base
# ===================================================================================

# ── Configuración inicial ─────────────────────────────────────────────────────

set -Eeuo pipefail
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

WAN_IF=""

CORE_GW_NAME="CORE-GW"
CORE_GW_IMAGE="ubuntu-net:24.04"

# WAN
GW_WAN_HOST_IP="172.16.255.1/30"
GW_WAN_GW_IP="172.16.255.2/30"
GW_WAN_NET="172.16.255.0/30"

# LAN
LAN_BR="br0"
LAN_IP="10.0.0.1/24"

log() { echo -e "🔹 $*"; }
ok()  { echo -e "✅ $*"; }
err() { echo -e "❌ $*" >&2; }

container_exists() {
  docker ps -a --format '{{.Names}}' | grep -qx "$1"
}

container_running() {
  docker ps --format '{{.Names}}' | grep -qx "$1"
}

veth_exists() {
  ip link show "$1" &>/dev/null
}

iptables_rule_exists() {
  iptables "$@" -C &>/dev/null
}

get_pid() {
  docker inspect -f '{{.State.Pid}}' "$CORE_GW_NAME"
}



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




# =========================================================
# MAIN
# =========================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "==[ EJECUTANDO LÓGICA: CORE-GW NETWORK ENGINE ]=="

  # -------------------------------------------------------
  # 1️⃣ Contenedor CORE-GW
  # -------------------------------------------------------
  if ! container_exists "$CORE_GW_NAME"; then
    log "Creando contenedor CORE-GW"
    docker run -dit \
      --name "$CORE_GW_NAME" \
      --hostname core-gw \
      --privileged \
      --network none \
      "$CORE_GW_IMAGE"
    ok "CORE-GW creado"
  else
    ok "CORE-GW ya existe"
  fi

  if ! container_running "$CORE_GW_NAME"; then
    log "Iniciando CORE-GW"
    docker start "$CORE_GW_NAME"
  fi

  CORE_PID="$(get_pid)"

  # -------------------------------------------------------
  # 2️⃣ VETH WAN
  # -------------------------------------------------------
  if ! veth_exists v-gw-wan; then
    log "Creando veth WAN"
    ip link add v-gw-wan type veth peer name v-host-gw
    ip link set v-gw-wan netns "$CORE_PID"
    ok "veth creado"
  else
    ok "veth WAN ya existe"
  fi

  ip addr show v-host-gw | grep -q "$GW_WAN_HOST_IP" || {
    ip addr add "$GW_WAN_HOST_IP" dev v-host-gw
  }
  ip link set v-host-gw up

  docker exec "$CORE_GW_NAME" ip addr show v-gw-wan | grep -q "$GW_WAN_GW_IP" || {
    docker exec "$CORE_GW_NAME" ip addr add "$GW_WAN_GW_IP" dev v-gw-wan
  }
  docker exec "$CORE_GW_NAME" ip link set v-gw-wan up

  # -------------------------------------------------------
  # 3️⃣ Routing CORE-GW
  # -------------------------------------------------------
  docker exec "$CORE_GW_NAME" ip route | grep -q default || {
    log "Configurando default route"
    docker exec "$CORE_GW_NAME" ip route add default via 172.16.255.1
  }

  # -------------------------------------------------------
  # 4️⃣ Bridge LAN
  # -------------------------------------------------------
  docker exec "$CORE_GW_NAME" ip link show "$LAN_BR" &>/dev/null || {
    log "Creando bridge LAN"
    docker exec "$CORE_GW_NAME" ip link add "$LAN_BR" type bridge
  }

  docker exec "$CORE_GW_NAME" ip addr show "$LAN_BR" | grep -q "$LAN_IP" || {
    docker exec "$CORE_GW_NAME" ip addr add "$LAN_IP" dev "$LAN_BR"
  }

  docker exec "$CORE_GW_NAME" ip link set "$LAN_BR" up

  # -------------------------------------------------------
  # 5️⃣ Forwarding
  # -------------------------------------------------------
  sysctl -q net.ipv4.ip_forward | grep -q '= 1' || sysctl -w net.ipv4.ip_forward=1
  docker exec "$CORE_GW_NAME" sysctl -q net.ipv4.ip_forward | grep -q '= 1' \
    || docker exec "$CORE_GW_NAME" sysctl -w net.ipv4.ip_forward=1

  # -------------------------------------------------------
  # 6️⃣ NAT y FORWARD (HOST)
  # -------------------------------------------------------
  iptables_rule_exists -t nat POSTROUTING -s "$GW_WAN_NET" ! -o docker0 -j MASQUERADE || {
    log "Agregando NAT"
    iptables -t nat -A POSTROUTING -s "$GW_WAN_NET" ! -o docker0 -j MASQUERADE
  }

  iptables_rule_exists FORWARD -s "$GW_WAN_NET" -j ACCEPT || {
    iptables -A FORWARD -s "$GW_WAN_NET" -j ACCEPT
  }

  iptables_rule_exists FORWARD -d "$GW_WAN_NET" -m state --state RELATED,ESTABLISHED -j ACCEPT || {
    iptables -A FORWARD -d "$GW_WAN_NET" -m state --state RELATED,ESTABLISHED -j ACCEPT
  }

  # -------------------------------------------------------
  # 7️⃣ Validación
  # -------------------------------------------------------
  log "Validando conectividad WAN"
  docker exec "$CORE_GW_NAME" ping -c1 8.8.8.8 &>/dev/null \
    && ok "CORE-GW tiene salida a Internet" \
    || err "Fallo de conectividad"

  ok "CORE-GW provisionado correctamente"
fi