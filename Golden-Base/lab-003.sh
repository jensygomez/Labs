#!/usr/bin/env bash
# ===================================================================================
# LABORATORIO LINUX PARA CERTIFICACIÓN LFCS/LFCE
# Topología: Infraestructura completa con contenedores Docker
# Versión: 2.0 (Optimizado con Imagen Osixia LDAP)
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
# Cambiamos a la imagen especializada
IMG_LDAP_OFFICIAL="osixia/openldap:1.5.0"

# Contenedores
CORE_GW="CORE-GW"
NS_SRV="NS-SRV"
SRV_LDAP="SRV-LDAP"

# Parámetros LDAP
LDAP_DOMAIN="laboratorio.local"
LDAP_ORG="Laboratorio"
LDAP_ADMIN_PASS="admin123"
LDAP_IP="10.0.0.11/24"
GW_IP="10.0.0.1"

# Interfaces
VETH_GW_SRV="v-gw-srv"
VETH_SRV_GW="v-srv-gw"
VETH_LDAP_SRV="v-ldap-srv"
VETH_SRV_LDAP="v-srv-ldap"

########################################
# UTILIDADES
########################################
ok()  { echo -e "${VERDE}✔ $*${NC}"; }
err() { echo -e "${ROJO}❌ $*${NC}" >&2; exit 1; }

container_exists() { docker ps -a --format '{{.Names}}' | grep -qx "$1"; }
container_pid()    { docker inspect -f '{{.State.Pid}}' "$1"; }
veth_exists_in_container() { docker exec "$1" ip link show "$2" &>/dev/null; }

########################################
# FASE 1 — CONTENEDOR NS-SRV (Switch L2)
########################################
create_ns_srv() {
  if container_exists "$NS_SRV"; then
    ok "NS-SRV ya existe"
    return
  fi
  docker run -d --name "$NS_SRV" --hostname ns-srv --cap-add NET_ADMIN --cap-add SYS_ADMIN --privileged "$IMG_NET" sleep infinity
  ok "NS-SRV creado"
}

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
# FASE 2 — UPLINK CORE-GW ↔ NS-SRV
########################################
setup_uplink() {
  if docker exec "$CORE_GW" ip link show "$VETH_GW_SRV" &>/dev/null 2>&1; then
    ok "Uplink ya configurado"
    return
  fi
  ip link add "$VETH_GW_SRV" type veth peer name "$VETH_SRV_GW"
  ip link set "$VETH_GW_SRV" netns "$(container_pid "$CORE_GW")"
  ip link set "$VETH_SRV_GW" netns "$(container_pid "$NS_SRV")"
  docker exec "$CORE_GW" ip link set "$VETH_GW_SRV" master br0
  docker exec "$CORE_GW" ip link set "$VETH_GW_SRV" up
  docker exec "$NS_SRV" ip link set "$VETH_SRV_GW" master br-srv
  docker exec "$NS_SRV" ip link set "$VETH_SRV_GW" up
  ok "Uplink CORE-GW ↔ NS-SRV configurado"
}

########################################
# FASE 3 — CONTENEDOR SRV-LDAP (OSIXIA)
########################################
create_srv_ldap() {
  if container_exists "$SRV_LDAP"; then
    ok "SRV-LDAP ya existe"
    return
  fi

  # La magia ocurre aquí: pasamos la config por variables de entorno
  docker run -d \
    --name "$SRV_LDAP" \
    --hostname srv-ldap \
    --env LDAP_ORGANISATION="$LDAP_ORG" \
    --env LDAP_DOMAIN="$LDAP_DOMAIN" \
    --env LDAP_ADMIN_PASSWORD="$LDAP_ADMIN_PASS" \
    --cap-add NET_ADMIN \
    --privileged \
    "$IMG_LDAP_OFFICIAL"

  ok "SRV-LDAP (Osixia) creado y auto-configurado"
}

########################################
# FASE 4 — RED SRV-LDAP
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

  ok "SRV-LDAP conectado a la red — $LDAP_IP"
}

########################################
# FASE 5 — CREAR ESTRUCTURA Y USUARIOS
########################################
setup_users() {
  # Esperar a que slapd esté listo (Osixia tarda unos segundos en iniciar)
  echo "⏳ Esperando a que LDAP responda..."
  until docker exec "$SRV_LDAP" ldapsearch -x -H ldap://localhost -b "dc=laboratorio,dc=local" >/dev/null 2>&1; do
    sleep 2
  done

  # Verificar si ya existen los usuarios
  if docker exec "$SRV_LDAP" ldapsearch -x -D "cn=admin,dc=laboratorio,dc=local" -w "$LDAP_ADMIN_PASS" "uid=juan" | grep -q "uid: juan"; then
    ok "Estructura LDAP ya existe"
    return
  fi

  # Crear OU y Usuarios en un solo paso
  docker exec -i "$SRV_LDAP" ldapadd -x -D "cn=admin,dc=laboratorio,dc=local" -w "$LDAP_ADMIN_PASS" <<EOF
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

dn: uid=maria,ou=People,dc=laboratorio,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: maria
sn: Garcia
cn: Maria Garcia
uidNumber: 1002
gidNumber: 1002
homeDirectory: /home/maria
loginShell: /bin/bash
userPassword: password123
EOF

  ok "Unidad People y usuarios (juan, maria) creados"
}

########################################
# MAIN
########################################
echo "==[ LAB 003 — SERVIDOR LDAP (VERSIÓN OPTIMIZADA) ]=="

container_exists "$CORE_GW" || err "CORE-GW no existe. Ejecuta lab-001.sh primero."

create_ns_srv
setup_bridge_srv
setup_uplink
create_srv_ldap
setup_ldap_network
setup_users

echo -e "\n${VERDE}¡LAB 003 COMPLETADO CON ÉXITO!${NC}"
print_topology 2>/dev/null || ok "Topología lista."