#!/usr/bin/env bash
# ===================================================================================
# LABORATORIO LINUX PARA CERTIFICACIÓN LFCS/LFCE
# Topología: Infraestructura completa con contenedores Docker
# Versión: 2 - Optimizada (usa imágenes preconstruidas)
# Laboratorio: 002 - Departamento RH (switch L2 + 3 PCs)
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
IMG_PC="ubuntu-pc:24.04"      # ← Imagen preconstruida con sssd y todo

# Contenedores
CORE_GW="CORE-GW"
NS_RH="NS-RH"
PC1="PC1-RH"
PC2="PC2-RH"
PC3="PC3-RH"

# IPs
GW_IP="10.0.0.1"
PC1_IP="10.0.0.21/24"
PC2_IP="10.0.0.22/24"
PC3_IP="10.0.0.23/24"

# Interfaces
VETH_GW_RH="v-gw-rh"
VETH_RH_GW="v-rh-gw"
VETH_PC1_RH="v-pc1-rh"
VETH_RH_PC1="v-rh-pc1"
VETH_PC2_RH="v-pc2-rh"
VETH_RH_PC2="v-rh-pc2"
VETH_PC3_RH="v-pc3-rh"
VETH_RH_PC3="v-rh-pc3"

########################################
# UTILIDADES
########################################
log() { echo -e "\n$INFO $*"; }
ok()  { echo "$OK $*"; }
err() { echo "$ERR $*" >&2; exit 1; }

image_exists() { docker images --format '{{.Repository}}:{{.Tag}}' | grep -qx "$1"; }
container_exists() { docker ps -a --format '{{.Names}}' | grep -qx "$1"; }
container_pid() { docker inspect -f '{{.State.Pid}}' "$1"; }
veth_exists_in_container() { docker exec "$1" ip link show "$2" &>/dev/null; }

########################################
# FASE 0 — VERIFICACIÓN DE IMÁGENES (YA NO CONSTRUYE)
########################################
check_images() {
  log "FASE 0 — Verificando imágenes necesarias"

  if ! image_exists "$IMG_NET"; then
    err "Imagen $IMG_NET no encontrada. Ejecuta 'bootstrap.sh' primero (opción 4 del menú)"
  fi
  ok "Imagen $IMG_NET disponible"

  if ! image_exists "$IMG_PC"; then
    err "Imagen $IMG_PC no encontrada. Ejecuta 'bootstrap.sh' primero (opción 4 del menú)"
  fi
  ok "Imagen $IMG_PC disponible"
}

########################################
# FASE 1 — CONTENEDOR NS-RH (switch L2)
########################################
create_ns_rh() {
  log "FASE 1 — Creando contenedor NS-RH"

  if container_exists "$NS_RH"; then
    ok "NS-RH ya existe"
    return
  fi

  docker run -d \
    --name "$NS_RH" \
    --hostname ns-rh \
    --cap-add NET_ADMIN \
    --cap-add SYS_ADMIN \
    --privileged \
    "$IMG_NET" \
    sleep infinity

  ok "NS-RH creado"
}

########################################
# FASE 2 — BRIDGE br-rh dentro de NS-RH
########################################
setup_bridge_rh() {
  log "FASE 2 — Bridge br-rh en NS-RH"

  if veth_exists_in_container "$NS_RH" br-rh; then
    ok "br-rh ya existe"
    return
  fi

  docker exec "$NS_RH" ip link add br-rh type bridge
  docker exec "$NS_RH" ip link set br-rh up

  ok "br-rh creado y UP"
}

########################################
# FASE 3 — UPLINK CORE-GW ↔ NS-RH
########################################
setup_uplink() {
  log "FASE 3 — Uplink CORE-GW ↔ NS-RH"

  if veth_exists_in_container "$CORE_GW" "$VETH_GW_RH"; then
    ok "Uplink ya configurado"
    return
  fi

  ip link add "$VETH_GW_RH" type veth peer name "$VETH_RH_GW"
  ip link set "$VETH_GW_RH" netns "$(container_pid "$CORE_GW")"
  ip link set "$VETH_RH_GW" netns "$(container_pid "$NS_RH")"

  docker exec "$CORE_GW" ip link set "$VETH_GW_RH" master br0
  docker exec "$CORE_GW" ip link set "$VETH_GW_RH" up
  docker exec "$NS_RH" ip link set "$VETH_RH_GW" master br-rh
  docker exec "$NS_RH" ip link set "$VETH_RH_GW" up

  ok "Uplink configurado"
}

########################################
# FASE 4 — NAT en CORE-GW para la LAN
########################################
setup_nat() {
  log "FASE 4 — NAT en CORE-GW"

  docker exec "$CORE_GW" iptables -t nat -C POSTROUTING \
    -s 10.0.0.0/24 -o v-gw-wan -j MASQUERADE 2>/dev/null && {
    ok "Regla NAT ya existe"
    return
  }

  docker exec "$CORE_GW" iptables -t nat -A POSTROUTING \
    -s 10.0.0.0/24 -o v-gw-wan -j MASQUERADE

  ok "Regla NAT agregada en CORE-GW"
}

########################################
# FASE 5 — PCs del departamento RH
########################################
create_pc() {
  local NAME="$1"
  local VETH_PC="$2"
  local VETH_RH="$3"
  local IP="$4"

  log "Creando $NAME ($IP)"

  if ! container_exists "$NAME"; then
    docker run -d \
      --name "$NAME" \
      --hostname "$(echo "$NAME" | tr '[:upper:]' '[:lower:]')" \
      --cap-add NET_ADMIN \
      --privileged \
      "$IMG_PC" \
      sleep infinity
    ok "$NAME creado"
  else
    ok "$NAME ya existe"
  fi

  if ! veth_exists_in_container "$NAME" "$VETH_PC"; then
    ip link add "$VETH_PC" type veth peer name "$VETH_RH"
    ip link set "$VETH_PC" netns "$(container_pid "$NAME")"
    ip link set "$VETH_RH" netns "$(container_pid "$NS_RH")"

    docker exec "$NS_RH" ip link set "$VETH_RH" master br-rh
    docker exec "$NS_RH" ip link set "$VETH_RH" up
    docker exec "$NAME" ip link set "$VETH_PC" up
    docker exec "$NAME" ip addr add "$IP" dev "$VETH_PC"
    docker exec "$NAME" ip route replace default via "$GW_IP"

    ok "$NAME conectada — $IP"
  else
    ok "$NAME ya tiene interfaz $VETH_PC"
  fi
}

setup_pcs() {
  log "FASE 5 — PCs del departamento RH"

  create_pc "$PC1" "$VETH_PC1_RH" "$VETH_RH_PC1" "$PC1_IP"
  create_pc "$PC2" "$VETH_PC2_RH" "$VETH_RH_PC2" "$PC2_IP"
  create_pc "$PC3" "$VETH_PC3_RH" "$VETH_RH_PC3" "$PC3_IP"
}




########################################
# PRINT TOPOLOGY (requerida por el engine)
########################################
print_topology() {
  local VERDE='\033[0;32m'
  local GRIS='\033[0;37m'
  local NC='\033[0m'

  echo -e ""
  echo -e "╔══════════════════════════════════════════╗"
  echo -e "║         LAB 002 — RESUMEN FINAL          ║"
  echo -e "╚══════════════════════════════════════════╝"
  echo -e ""
  echo -e "  ${VERDE}✔ Switch L2${NC}    NS-RH (br-rh)"
  echo -e "  ${VERDE}✔ Uplink${NC}       v-gw-rh (br0) ↔ v-rh-gw (NS-RH)"
  echo -e "  ${VERDE}✔ PC1-RH${NC}       10.0.0.21/24"
  echo -e "  ${VERDE}✔ PC2-RH${NC}       10.0.0.22/24"
  echo -e "  ${VERDE}✔ PC3-RH${NC}       10.0.0.23/24"
  echo -e "  ${VERDE}✔ NAT${NC}          10.0.0.0/24 → INTERNET (via CORE-GW)"
  echo -e "  ${VERDE}✔ L2${NC}           PC1↔PC2↔PC3 (mismo bridge)"
  echo -e "  ${VERDE}✔ L3${NC}           PCs → CORE-GW → Internet"
  echo -e ""
  echo -e ""
  echo -e "╔══════════════════════════════════════════╗"
  echo -e "║       PRÓXIMO — LAB 003: LDAP            ║"
  echo -e "╚══════════════════════════════════════════╝"
  echo -e ""
  echo -e "  Objetivo: Centralización de usuarios con OpenLDAP"
  echo -e ""
  echo -e "  Por crear:"
  echo -e "  ${GRIS}  ░ Contenedor   NS-SRV${NC}"
  echo -e "  ${GRIS}  ░ Bridge       br-srv${NC}"
  echo -e "  ${GRIS}  ░ SRV-LDAP     10.0.0.11  (OpenLDAP)${NC}"
  echo -e ""
  echo -e "  Configuración en PCs de RH:"
  echo -e "  ${GRIS}  ░ Instalar SSSD + PAM + NSS${NC}"
  echo -e "  ${GRIS}  ░ Apuntar a SRV-LDAP para autenticación${NC}"
  echo -e "  ${GRIS}  ░ Crear usuarios en LDAP (ej: juan, maria)${NC}"
  echo -e ""
  echo -e "  Validaciones esperadas:"
  echo -e "  ${GRIS}  ░ Login con usuario LDAP desde PC1-RH${NC}"
  echo -e "  ${GRIS}  ░ Mismo usuario accesible desde PC2-RH y PC3-RH${NC}"
  echo -e ""
}

########################################
# MAIN
########################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo -e "${AZUL}${BOLD}==[ LAB 002 — DEPARTAMENTO RH | ARQUITECTURA LINUX ]==${NC}"

  # Verificar que el lab-001 está corriendo
  container_exists "$CORE_GW" || err "CORE-GW no existe. Ejecuta lab-001.sh primero."
  
  # SOLO VERIFICAR - NO CONSTRUIR
  check_images
  
  create_ns_rh
  setup_bridge_rh
  setup_uplink
  setup_nat
  setup_pcs

  echo
  ok "LAB 002 COMPLETADO"
  sleep 5
fi
