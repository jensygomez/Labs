#!/usr/bin/env bash
# ===================================================================================
# LABORATORIO LINUX PARA CERTIFICACIÓN LFCS/LFCE
# Laboratorio: 003 - Servidor LDAP
# Refactorizado: ubuntu:24.04 + slapd instalado manualmente
# ===================================================================================

set -Eeuo pipefail

# ── Colores ───────────────────────────────────────────────────────────────────
VERDE='\033[0;32m'
ROJO='\033[0;31m'
NC='\033[0m'

########################################
# VARIABLES GLOBALES
########################################
IMG_NET="ubuntu-net:24.04"
IMG_BASE="ubuntu:24.04"          # ← Cambiado: imagen base limpia

CORE_GW="CORE-GW"
NS_SRV="NS-SRV"
SRV_LDAP="SRV-LDAP"

LDAP_DOMAIN="laboratorio.local"
LDAP_ORG="Laboratorio"
LDAP_ADMIN_PASS="admin123"
LDAP_IP="10.0.0.11/24"
GW_IP="10.0.0.1"

VETH_GW_SRV="v-gw-srv";   VETH_SRV_GW="v-srv-gw"
VETH_LDAP_SRV="v-ldap-srv"; VETH_SRV_LDAP="v-srv-ldap"

########################################
# UTILIDADES
########################################
ok()  { echo -e "${VERDE}✔ $*${NC}"; }
err() { echo -e "${ROJO}❌ $*${NC}" >&2; exit 1; }

container_exists()         { docker ps -a --format '{{.Names}}' | grep -qx "$1"; }
container_pid()            { docker inspect -f '{{.State.Pid}}' "$1"; }
veth_exists_in_container() { docker exec "$1" ip link show "$2" &>/dev/null; }

########################################
# FASES DE INFRAESTRUCTURA (sin cambios)
########################################
create_ns_srv() {
  if container_exists "$NS_SRV"; then ok "NS-SRV listo"; return; fi
  docker run -d --name "$NS_SRV" --hostname ns-srv \
    --cap-add NET_ADMIN --cap-add SYS_ADMIN --privileged \
    "$IMG_NET" sleep infinity
  ok "NS-SRV creado"
}

setup_bridge_srv() {
  if veth_exists_in_container "$NS_SRV" br-srv; then ok "br-srv listo"; return; fi
  docker exec "$NS_SRV" ip link add br-srv type bridge
  docker exec "$NS_SRV" ip link set br-srv up
  ok "br-srv configurado"
}

setup_uplink() {
  if docker exec "$CORE_GW" ip link show "$VETH_GW_SRV" &>/dev/null 2>&1; then ok "Uplink listo"; return; fi
  ip link add "$VETH_GW_SRV" type veth peer name "$VETH_SRV_GW"
  ip link set "$VETH_GW_SRV" netns "$(container_pid "$CORE_GW")"
  ip link set "$VETH_SRV_GW" netns "$(container_pid "$NS_SRV")"
  docker exec "$CORE_GW" ip link set "$VETH_GW_SRV" master br0
  docker exec "$CORE_GW" ip link set "$VETH_GW_SRV" up
  docker exec "$NS_SRV"  ip link set "$VETH_SRV_GW" master br-srv
  docker exec "$NS_SRV"  ip link set "$VETH_SRV_GW" up
  ok "Uplink CORE-GW ↔ NS-SRV configurado"
}

########################################
# FASE 4 — SERVIDOR LDAP (ubuntu:24.04 + slapd)
########################################
create_srv_ldap() {
  if container_exists "$SRV_LDAP"; then ok "SRV-LDAP ya existe"; return; fi

  # 1. Arrancamos container base
  docker run -d \
    --name "$SRV_LDAP" \
    --hostname srv-ldap \
    --cap-add NET_ADMIN \
    --privileged \
    "$IMG_BASE" \
    sleep infinity
  ok "SRV-LDAP container creado"

  # 2. Instalamos slapd de forma no interactiva
  #    CLAVE: comillas dobles en bash -c → las variables del host se expanden
  docker exec "$SRV_LDAP" bash -c "
    export DEBIAN_FRONTEND=noninteractive
    echo 'slapd slapd/root_password password ${LDAP_ADMIN_PASS}'       | debconf-set-selections
    echo 'slapd slapd/root_password_again password ${LDAP_ADMIN_PASS}' | debconf-set-selections
    echo 'slapd slapd/domain string ${LDAP_DOMAIN}'                    | debconf-set-selections
    echo 'slapd shared/organization string ${LDAP_ORG}'                | debconf-set-selections
    apt-get update -qq
    apt-get install -y slapd ldap-utils
  "
  ok "slapd instalado"

  # 3. Arrancamos slapd manualmente (policy-rc.d lo bloquea en containers)
  docker exec "$SRV_LDAP" slapd -u openldap -g openldap
  ok "SRV-LDAP iniciado"
}

########################################
# FASE 5 — RED SRV-LDAP (sin cambios)
########################################
setup_ldap_network() {
  if veth_exists_in_container "$SRV_LDAP" "$VETH_LDAP_SRV"; then ok "Red LDAP lista"; return; fi

  ip link add "$VETH_SRV_LDAP" type veth peer name "$VETH_LDAP_SRV"
  ip link set "$VETH_SRV_LDAP" netns "$(container_pid "$NS_SRV")"
  ip link set "$VETH_LDAP_SRV" netns "$(container_pid "$SRV_LDAP")"

  docker exec "$NS_SRV"   ip link set "$VETH_SRV_LDAP" master br-srv
  docker exec "$NS_SRV"   ip link set "$VETH_SRV_LDAP" up
  docker exec "$SRV_LDAP" ip link set "$VETH_LDAP_SRV" up
  docker exec "$SRV_LDAP" ip addr add "$LDAP_IP" dev "$VETH_LDAP_SRV"
  docker exec "$SRV_LDAP" ip route replace default via "$GW_IP"

  ok "Red SRV-LDAP configurada ($LDAP_IP)"
}

########################################
# FASE 6 — VERIFICAR Y POBLAR DATOS
########################################
setup_users() {
  echo "⏳ Esperando disponibilidad de LDAP..."

  local count=0
  set +e
  while true; do
    docker exec "$SRV_LDAP" ldapsearch -x -H ldap://localhost \
      -b "dc=laboratorio,dc=local" >/dev/null 2>&1
    STATUS=$?

    if [ $STATUS -eq 0 ]; then
      echo -e "\n${VERDE}✔ LDAP está Online!${NC}"
      break
    fi

    echo "Intento $((count+1)): Servidor aún iniciando..."
    sleep 3
    ((count++))

    if [ $count -gt 25 ]; then
      err "LDAP no arrancó a tiempo."
    fi
  done
  set -e

  # Insertar OU y usuario
  # CLAVE: EOF sin comillas simples → variables expandidas correctamente
  docker exec -i "$SRV_LDAP" ldapadd \
    -x \
    -D "cn=admin,dc=laboratorio,dc=local" \
    -w "$LDAP_ADMIN_PASS" <<EOF
dn: ou=People,dc=laboratorio,dc=local
objectClass: organizationalUnit
ou: People

dn: uid=juan,ou=People,dc=laboratorio,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: juan
sn: Perez
cn: Juan Perez
uidNumber: 1001
gidNumber: 1001
homeDirectory: /home/juan
loginShell: /bin/bash
userPassword: password123
EOF

  ok "Usuarios creados en LDAP"
}

########################################
# MAIN
########################################
echo "==[ LABORATORIO 003 — SERVIDOR LDAP ]=="

create_ns_srv
setup_bridge_srv
setup_uplink
create_srv_ldap
setup_ldap_network
setup_users

ok "¡Escenario LDAP listo!"