#!/usr/bin/env bash
# ===================================================================================
# LABORATORIO LINUX PARA CERTIFICACIÓN LFCS/LFCE
# Topología: Infraestructura completa con contenedores Docker
# Versión: 1
# Laboratorio: 002 - Departamento RH (switch L2 + 3 PCs)
# ===================================================================================

set -Eeuo pipefail

# ── Colores ───────────────────────────────────────────────────────────────────
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
NC='\033[0m'

########################################
# VARIABLES GLOBALES
########################################
IMG_NET="ubuntu-net:24.04"
IMG_PC="ubuntu-pc:24.04"

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

# Interfaces — uplink CORE-GW ↔ NS-RH
VETH_GW_RH="v-gw-rh"       # extremo en CORE-GW (enchufado a br0)
VETH_RH_GW="v-rh-gw"       # extremo en NS-RH   (enchufado a br-rh)

# Interfaces — NS-RH ↔ PCs
VETH_PC1_RH="v-pc1-rh"     # extremo en PC1-RH
VETH_RH_PC1="v-rh-pc1"     # extremo en NS-RH

VETH_PC2_RH="v-pc2-rh"     # extremo en PC2-RH
VETH_RH_PC2="v-rh-pc2"     # extremo en NS-RH

VETH_PC3_RH="v-pc3-rh"     # extremo en PC3-RH
VETH_RH_PC3="v-rh-pc3"     # extremo en NS-RH

########################################
# UTILIDADES
########################################
log() { :; }
ok()  { echo -e "${VERDE}✔ $*${NC}"; }
err() { echo -e "${ROJO}❌ $*${NC}" >&2; exit 1; }

image_exists() {
  docker images --format '{{.Repository}}:{{.Tag}}' | grep -qx "$1"
}

container_exists() {
  docker ps -a --format '{{.Names}}' | grep -qx "$1"
}

container_pid() {
  docker inspect -f '{{.State.Pid}}' "$1"
}

veth_exists_in_container() {
  docker exec "$1" ip link show "$2" &>/dev/null
}


########################################
# FASE 0 — IMAGEN LDAP
########################################
build_image_pc() {
  if image_exists "$IMG_PC"; then
    ok "Imagen $IMG_PC ya existe"
    return
  fi

  local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local DOCKERFILE_PATH=""

  if [ -f "$SCRIPT_DIR/Dockerfile.pc" ]; then
    DOCKERFILE_PATH="$SCRIPT_DIR/Dockerfile.pc"
  elif [ -f "$SCRIPT_DIR/../Dockerfile.pc" ]; then
    DOCKERFILE_PATH="$SCRIPT_DIR/../Dockerfile.pc"
  fi

  [ -z "$DOCKERFILE_PATH" ] && err "No se encontró Dockerfile.pc"

  local CONTEXT_DIR="$(dirname "$DOCKERFILE_PATH")"
  docker build -t "$IMG_PC" -f "$DOCKERFILE_PATH" "$CONTEXT_DIR"
  ok "Imagen $IMG_PC creada"
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

  # Si el veth ya está dentro de CORE-GW, asumimos que esta fase ya se hizo
  if veth_exists_in_container "$CORE_GW" "$VETH_GW_RH"; then
    ok "Uplink ya configurado"
    return
  fi

  # Crear el par de veth en el host
  ip link add "$VETH_GW_RH" type veth peer name "$VETH_RH_GW"

  # Mover cada extremo a su contenedor
  ip link set "$VETH_GW_RH" netns "$(container_pid "$CORE_GW")"
  ip link set "$VETH_RH_GW" netns "$(container_pid "$NS_RH")"

  # Enchufar v-gw-rh al bridge br0 del CORE-GW
  docker exec "$CORE_GW" ip link set "$VETH_GW_RH" master br0
  docker exec "$CORE_GW" ip link set "$VETH_GW_RH" up

  # Enchufar v-rh-gw al bridge br-rh del NS-RH
  docker exec "$NS_RH" ip link set "$VETH_RH_GW" master br-rh
  docker exec "$NS_RH" ip link set "$VETH_RH_GW" up

  ok "Uplink configurado"
}

########################################
# FASE 4 — NAT en CORE-GW para la LAN
########################################
setup_nat() {
  log "FASE 4 — NAT en CORE-GW"

  # Verificar si la regla ya existe
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

# Función genérica para crear una PC y conectarla al bridge br-rh
# Uso: create_pc NOMBRE VETH_PC VETH_RH IP
create_pc() {
  local NAME="$1"
  local VETH_PC="$2"     # extremo que va a la PC
  local VETH_RH="$3"     # extremo que va a NS-RH
  local IP="$4"

  log "Creando $NAME ($IP)"

  # Crear contenedor si no existe
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

  # Crear veth y conectar solo si no existe ya en la PC
  if ! veth_exists_in_container "$NAME" "$VETH_PC"; then

    ip link add "$VETH_PC" type veth peer name "$VETH_RH"

    ip link set "$VETH_PC" netns "$(container_pid "$NAME")"
    ip link set "$VETH_RH" netns "$(container_pid "$NS_RH")"

    # Conectar extremo NS-RH al bridge
    docker exec "$NS_RH" ip link set "$VETH_RH" master br-rh
    docker exec "$NS_RH" ip link set "$VETH_RH" up

    # Levantar extremo de la PC
    docker exec "$NAME" ip link set "$VETH_PC" up

    # Asignar IP y ruta default
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
  echo "==[ LAB 002 — DEPARTAMENTO RH | ARQUITECTURA LINUX ]=="

  # Verificar que el lab-001 está corriendo
  container_exists "$CORE_GW" || err "CORE-GW no existe. Ejecuta lab-001.sh primero."
  build_image_pc
  create_ns_rh
  setup_bridge_rh
  setup_uplink
  setup_nat
  setup_pcs

  echo
  ok "LAB 002 COMPLETADO"
  sleep 5
fi