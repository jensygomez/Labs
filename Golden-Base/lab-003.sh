#!/usr/bin/env bash
# ===================================================================================
# LABORATORIO LINUX PARA CERTIFICACIÓN LFCS/LFCE
# Laboratorio: 003 - Servidor LDAP
# Versión: 2 - Optimizada (usa imágenes preconstruidas)
# ===================================================================================

set -Eeuo pipefail

VERDE='\033[0;32m'
ROJO='\033[0;31m'
NC='\033[0m'

ok()  { echo -e "${VERDE}✔ $*${NC}"; }
err() { echo -e "${ROJO}❌ $*${NC}" >&2; exit 1; }

container_exists()         { docker ps -a --format '{{.Names}}' | grep -qx "$1"; }
container_pid()            { docker inspect -f '{{.State.Pid}}' "$1"; }
veth_exists_in_container() { docker exec "$1" ip link show "$2" &>/dev/null; }
image_exists()             { docker images --format '{{.Repository}}:{{.Tag}}' | grep -qx "$1"; }

########################################
# FASE 0 — VERIFICAR IMAGEN LDAP (YA NO CONSTRUYE)
########################################
check_image_ldap() {
  if image_exists "ubuntu-ldap:24.04"; then
    ok "Imagen ubuntu-ldap:24.04 disponible"
  else
    err "Imagen ubuntu-ldap:24.04 no encontrada. Ejecuta 'bootstrap.sh' primero (opción 4 del menú)"
  fi
}

########################################
# FASES DE INFRAESTRUCTURA
########################################
create_ns_srv() {
  if container_exists "NS-SRV"; then ok "NS-SRV listo"; return; fi
  docker run -d --name "NS-SRV" --hostname ns-srv \
    --cap-add NET_ADMIN --cap-add SYS_ADMIN --privileged \
    "ubuntu-net:24.04" sleep infinity
  ok "NS-SRV creado"
}

setup_bridge_srv() {
  if veth_exists_in_container "NS-SRV" br-srv; then ok "br-srv listo"; return; fi
  docker exec "NS-SRV" ip link add br-srv type bridge
  docker exec "NS-SRV" ip link set br-srv up
  ok "br-srv configurado"
}

setup_uplink() {
  if docker exec "CORE-GW" ip link show "v-gw-srv" &>/dev/null 2>&1; then ok "Uplink listo"; return; fi
  ip link add "v-gw-srv" type veth peer name "v-srv-gw"
  ip link set "v-gw-srv" netns "$(container_pid "CORE-GW")"
  ip link set "v-srv-gw" netns "$(container_pid "NS-SRV")"
  docker exec "CORE-GW" ip link set "v-gw-srv" master br0
  docker exec "CORE-GW" ip link set "v-gw-srv" up
  docker exec "NS-SRV"  ip link set "v-srv-gw" master br-srv
  docker exec "NS-SRV"  ip link set "v-srv-gw" up
  ok "Uplink CORE-GW ↔ NS-SRV configurado"
}

########################################
# FASE 4 — SERVIDOR LDAP
########################################
create_srv_ldap() {
  if container_exists "SRV-LDAP"; then 
    ok "SRV-LDAP ya existe"
    return
  fi

  docker run -d \
    --name "SRV-LDAP" \
    --hostname srv-ldap \
    --cap-add NET_ADMIN \
    --privileged \
    "ubuntu-ldap:24.04"
    
  ok "SRV-LDAP container creado"
  
  # Verificar que el usuario openldap existe
  docker exec "SRV-LDAP" id openldap || echo "Usuario openldap no encontrado"
  
  # Verificar directorios necesarios
  docker exec "SRV-LDAP" ls -la /var/lib/ldap/
  docker exec "SRV-LDAP" ls -la /etc/ldap/slapd.d/
  
  # Iniciar slapd con opciones explícitas
  docker exec "SRV-LDAP" slapd -u openldap -g openldap -h "ldap:/// ldapi:///" -F /etc/ldap/slapd.d/
  
  # Verificar que está corriendo
  sleep 2
  docker exec "SRV-LDAP" ps aux | grep slapd
  
  ok "slapd iniciado"
}

########################################
# FASE 5 — RED SRV-LDAP
########################################
setup_ldap_network() {
  if veth_exists_in_container "SRV-LDAP" "v-ldap-srv"; then ok "Red LDAP lista"; return; fi

  ip link add "v-srv-ldap" type veth peer name "v-ldap-srv"
  ip link set "v-srv-ldap" netns "$(container_pid "NS-SRV")"
  ip link set "v-ldap-srv" netns "$(container_pid "SRV-LDAP")"

  docker exec "NS-SRV"   ip link set "v-srv-ldap" master br-srv
  docker exec "NS-SRV"   ip link set "v-srv-ldap" up
  docker exec "SRV-LDAP" ip link set "v-ldap-srv" up
  docker exec "SRV-LDAP" ip addr add "10.0.0.11/24" dev "v-ldap-srv"
  docker exec "SRV-LDAP" ip route replace default via "10.0.0.1"

  ok "Red SRV-LDAP configurada (10.0.0.11/24)"
}

########################################
# FASE 6 — VERIFICAR Y POBLAR DATOS
########################################
setup_users() {
  echo "⏳ Esperando disponibilidad de LDAP..."

  local count=0
  set +e
  while true; do
    # Prueba primero con anonymous bind
    docker exec "SRV-LDAP" ldapsearch -x -H ldap://localhost \
      -b "dc=laboratorio,dc=local" >/dev/null 2>&1
    STATUS=$?

    if [ $STATUS -eq 0 ]; then
      echo -e "\n${VERDE}✔ LDAP está Online!${NC}"
      
      # 👇 ESPERA ADICIONAL para que slapd termine de cargar la configuración
      echo "⏳ Esperando 5 segundos para que slapd estabilice..."
      sleep 5
      
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

  # Ahora intenta agregar usuarios
  docker exec -i "SRV-LDAP" ldapadd -x \
    -D "cn=admin,dc=laboratorio,dc=local" \
    -w "admin123" \
    -H ldap://localhost <<'EOF'

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

# Verificar que CORE-GW existe (lab-001)
container_exists "CORE-GW" || err "CORE-GW no existe. Ejecuta lab-001.sh primero."

# SOLO VERIFICAR - NO CONSTRUIR
check_image_ldap

create_ns_srv
setup_bridge_srv
setup_uplink
create_srv_ldap
setup_ldap_network
setup_users

ok "¡Escenario LDAP listo!"