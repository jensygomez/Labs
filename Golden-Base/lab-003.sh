#!/usr/bin/env bash
# ===================================================================================
# LABORATORIO LINUX PARA CERTIFICACIÓN LFCS/LFCE
# Topología: Infraestructura completa con contenedores Docker
# Versión: 1
# Laboratorio: 003 - Servidor LDAP (NS-SRV + SRV-LDAP)
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
IMG_LDAP="ubuntu-ldap:24.04"

# Contenedores
CORE_GW="CORE-GW"
NS_SRV="NS-SRV"
SRV_LDAP="SRV-LDAP"

# IPs
GW_IP="10.0.0.1"
LDAP_IP="10.0.0.11/24"
LDAP_DOMAIN="laboratorio.local"
LDAP_ORG="Laboratorio"
LDAP_ADMIN_PASS="admin123"

# Interfaces — uplink CORE-GW ↔ NS-SRV
VETH_GW_SRV="v-gw-srv"
VETH_SRV_GW="v-srv-gw"

# Interfaces — NS-SRV ↔ SRV-LDAP
VETH_LDAP_SRV="v-ldap-srv"
VETH_SRV_LDAP="v-srv-ldap"

########################################
# UTILIDADES
########################################
log() { :; }
ok()  { echo -e "${VERDE}✔ $*${NC}"; }
err() { echo -e "${ROJO}❌ $*${NC}" >&2; exit 1; }

container_exists() {
  docker ps -a --format '{{.Names}}' | grep -qx "$1"
}

container_pid() {
  docker inspect -f '{{.State.Pid}}' "$1"
}

veth_exists_in_container() {
  docker exec "$1" ip link show "$2" &>/dev/null
}

image_exists() {
  docker images --format '{{.Repository}}:{{.Tag}}' | grep -qx "$1"
}

########################################
# FASE 0 — IMAGEN LDAP
########################################
build_image_ldap() {
  if image_exists "$IMG_LDAP"; then
    ok "Imagen $IMG_LDAP ya existe"
    return
  fi

  local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local DOCKERFILE_PATH=""

  if [ -f "$SCRIPT_DIR/Dockerfile.ldap" ]; then
    DOCKERFILE_PATH="$SCRIPT_DIR/Dockerfile.ldap"
  elif [ -f "$SCRIPT_DIR/../Dockerfile.ldap" ]; then
    DOCKERFILE_PATH="$SCRIPT_DIR/../Dockerfile.ldap"
  fi

  [ -z "$DOCKERFILE_PATH" ] && err "No se encontró Dockerfile.ldap"

  local CONTEXT_DIR="$(dirname "$DOCKERFILE_PATH")"
  docker build -t "$IMG_LDAP" -f "$DOCKERFILE_PATH" "$CONTEXT_DIR"
  ok "Imagen $IMG_LDAP creada"
}

########################################
# FASE 1 — CONTENEDOR NS-SRV (switch L2)
########################################
create_ns_srv() {
  if container_exists "$NS_SRV"; then
    ok "NS-SRV ya existe"
    return
  fi

  docker run -d \
    --name "$NS_SRV" \
    --hostname ns-srv \
    --cap-add NET_ADMIN \
    --cap-add SYS_ADMIN \
    --privileged \
    "$IMG_NET" \
    sleep infinity

  ok "NS-SRV creado"
}

########################################
# FASE 2 — BRIDGE br-srv dentro de NS-SRV
########################################
setup_bridge_srv() {
  if veth_exists_in_container "$NS_SRV" br-srv; then
    ok "br-srv ya existe"
    return
  fi

  docker exec "$NS_SRV" ip link add br-srv type bridge
  docker exec "$NS_SRV" ip link set br-srv up
  ok "br-srv creado y UP"
}

########################################
# FASE 3 — UPLINK CORE-GW ↔ NS-SRV
########################################
setup_uplink() {
  # Chequeo TOLERANTE a pipefail (set +e temporal)
  if docker exec "$CORE_GW" ip link show "$VETH_GW_SRV" &>/dev/null 2>&1; then
    ok "Uplink ya configurado"
    return
  fi

  # Crear veth pair
  ip link add "$VETH_GW_SRV" type veth peer name "$VETH_SRV_GW" || {
    err "Fallo creando veth pair $VETH_GW_SRV"
  }

  # Mover a namespaces
  ip link set "$VETH_GW_SRV" netns "$(container_pid "$CORE_GW")"
  ip link set "$VETH_SRV_GW" netns "$(container_pid "$NS_SRV")"

  # CORE-GW: master br0 + UP
  docker exec "$CORE_GW" ip link set "$VETH_GW_SRV" master br0
  docker exec "$CORE_GW" ip link set "$VETH_GW_SRV" up

  # NS-SRV: master br-srv + UP  
  docker exec "$NS_SRV" ip link set "$VETH_SRV_GW" master br-srv
  docker exec "$NS_SRV" ip link set "$VETH_SRV_GW" up

  ok "Uplink CORE-GW ↔ NS-SRV configurado"
}


########################################
# FASE 4 — CONTENEDOR SRV-LDAP
########################################
create_srv_ldap() {
  if container_exists "$SRV_LDAP"; then
    ok "SRV-LDAP ya existe"
    return
  fi

  docker run -d \
    --name "$SRV_LDAP" \
    --hostname srv-ldap \
    --cap-add NET_ADMIN \
    --cap-add SYS_ADMIN \
    --privileged \
    "$IMG_LDAP" \
    sleep infinity

  ok "SRV-LDAP creado"
}

########################################
# FASE 5 — CONECTAR SRV-LDAP a NS-SRV
########################################
setup_ldap_network() {
  if veth_exists_in_container "$SRV_LDAP" "$VETH_LDAP_SRV"; then
    ok "Red SRV-LDAP ya configurada"
    return
  fi

  ip link add "$VETH_SRV_LDAP" type veth peer name "$VETH_LDAP_SRV"

  ip link set "$VETH_SRV_LDAP" netns "$(container_pid "$NS_SRV")"
  ip link set "$VETH_LDAP_SRV" netns "$(container_pid "$SRV_LDAP")"

  docker exec "$NS_SRV" ip link set "$VETH_SRV_LDAP" master br-srv
  docker exec "$NS_SRV" ip link set "$VETH_SRV_LDAP" up

  docker exec "$SRV_LDAP" ip link set "$VETH_LDAP_SRV" up
  docker exec "$SRV_LDAP" ip addr add "$LDAP_IP" dev "$VETH_LDAP_SRV"
  docker exec "$SRV_LDAP" ip route replace default via "$GW_IP"

  ok "SRV-LDAP conectado — $LDAP_IP"
}

echo "[DEBUG] SRV_LDAP = '$SRV_LDAP'"
if [ -z "$SRV_LDAP" ]; then
    echo "[ERROR] SRV_LDAP no está definida"
    exit 1
fi
########################################
# FASE 6 — CONFIGURAR OPENLDAP
########################################
setup_ldap() {

  echo "[INFO] Iniciando setup OpenLDAP en SRV-LDAP"

  # Verificar contenedor en ejecución
  if ! docker inspect -f '{{.State.Running}}' SRV-LDAP 2>/dev/null | grep -q true; then
    echo "[ERROR] Contenedor SRV-LDAP no está en ejecución"
    return 1
  fi

  # Actualizar repositorios (no aborta si hay warning)
  docker exec SRV-LDAP apt-get update -qq || true

  # Instalar paquetes LDAP (idempotente)
  docker exec SRV-LDAP dpkg -s slapd ldap-utils >/dev/null 2>&1 || \
    docker exec SRV-LDAP apt-get install -y slapd ldap-utils

  # Preconfigurar slapd
  docker exec -i SRV-LDAP debconf-set-selections <<EOF
slapd slapd/domain string laboratorio.local
slapd shared/organization string Laboratorio
slapd slapd/password1 password admin123
slapd slapd/password2 password admin123
slapd slapd/purge_database boolean true
EOF

  # Reconfigurar slapd
  docker exec SRV-LDAP env DEBIAN_FRONTEND=noninteractive dpkg-reconfigure slapd

  # Asegurar slapd corriendo
  if ! docker exec SRV-LDAP pgrep slapd >/dev/null; then
    docker exec SRV-LDAP service slapd start
    sleep 3
  fi

  # Esperar LDAP disponible
  for i in {1..10}; do
    if docker exec SRV-LDAP ldapsearch -x -H ldap://localhost -b "" -s base >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done

  # Crear OU usuarios (idempotente)
  if docker exec SRV-LDAP ldapsearch -x \
      -D "cn=admin,dc=laboratorio,dc=local" \
      -w admin123 \
      -b "ou=usuarios,dc=laboratorio,dc=local" \
      -H ldap://localhost >/dev/null 2>&1; then

    echo "[OK] OU usuarios ya existe"

  else

    docker exec SRV-LDAP ldapadd -x \
      -D "cn=admin,dc=laboratorio,dc=local" \
      -w admin123 \
      -H ldap://localhost <<'EOF'
dn: ou=usuarios,dc=laboratorio,dc=local
objectClass: organizationalUnit
ou: usuarios
EOF
  fi

  echo "[OK] OpenLDAP configurado correctamente"
}

########################################
# FASE 7 — CREAR USUARIOS LDAP
########################################
setup_users() {
  # Verificar si los usuarios ya existen
  if docker exec "$SRV_LDAP" slapcat 2>/dev/null | grep -q "uid=juan"; then
    ok "Usuarios LDAP ya existen"
    return
  fi

  local HASH
  HASH=$(docker exec "$SRV_LDAP" slappasswd -s "$LDAP_ADMIN_PASS")

  docker exec "$SRV_LDAP" bash -c "ldapadd -x -D 'cn=admin,dc=laboratorio,dc=local' -w '$LDAP_ADMIN_PASS' <<EOF
dn: uid=juan,ou=usuarios,dc=laboratorio,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: juan
cn: Juan Perez
sn: Perez
uidNumber: 1001
gidNumber: 1001
homeDirectory: /home/juan
loginShell: /bin/bash
userPassword: $HASH

dn: uid=maria,ou=usuarios,dc=laboratorio,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: maria
cn: Maria Garcia
sn: Garcia
uidNumber: 1002
gidNumber: 1002
homeDirectory: /home/maria
loginShell: /bin/bash
userPassword: $HASH
EOF"

  ok "Usuarios juan y maria creados"
}



########################################
# PRINT TOPOLOGY
########################################
print_topology() {
  local VERDE='\033[0;32m'
  local GRIS='\033[0;37m'
  local NC='\033[0m'

  echo -e ""
  echo -e "╔══════════════════════════════════════════╗"
  echo -e "║         LAB 003 — RESUMEN FINAL          ║"
  echo -e "╚══════════════════════════════════════════╝"
  echo -e ""
  echo -e "  ${VERDE}✔ Switch L2${NC}    NS-SRV (br-srv)"
  echo -e "  ${VERDE}✔ Uplink${NC}       v-gw-srv (br0) ↔ v-srv-gw (NS-SRV)"
  echo -e "  ${VERDE}✔ SRV-LDAP${NC}     10.0.0.11/24"
  echo -e "  ${VERDE}✔ Dominio${NC}      $LDAP_DOMAIN"
  echo -e "  ${VERDE}✔ Admin${NC}        cn=admin,dc=laboratorio,dc=local"
  echo -e "  ${VERDE}✔ Usuarios${NC}     juan, maria"
  echo -e ""
  echo -e ""
  echo -e "╔══════════════════════════════════════════╗"
  echo -e "║     PRÓXIMO — LAB 004: CLIENTE LDAP      ║"
  echo -e "╚══════════════════════════════════════════╝"
  echo -e ""
  echo -e "  Objetivo: Autenticación centralizada en PCs de RH"
  echo -e ""
  echo -e "  Por configurar:"
  echo -e "  ${GRIS}  ░ Instalar sssd + pam en PC1-RH, PC2-RH, PC3-RH${NC}"
  echo -e "  ${GRIS}  ░ Apuntar PCs a SRV-LDAP (10.0.0.11)${NC}"
  echo -e "  ${GRIS}  ░ Login con usuario juan desde cualquier PC${NC}"
  echo -e ""
}

########################################
# MAIN
########################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "==[ LAB 003 — SERVIDOR LDAP | ARQUITECTURA LINUX ]=="

  container_exists "$CORE_GW" || err "CORE-GW no existe. Ejecuta lab-001.sh primero."

  build_image_ldap
  create_ns_srv
  setup_bridge_srv
  setup_uplink
  create_srv_ldap
  setup_ldap_network

  docker exec SRV-LDAP ping -c1 8.8.8.8 >/dev/null 2>&1 || \
  err "SRV-LDAP no tiene salida a Internet"

  setup_ldap
  setup_users

  echo
  print_topology
  sleep 5
fi