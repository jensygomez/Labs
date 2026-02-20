#!/bin/bash
# ===================================================================================
# LABORATORIO LINUX PARA CERTIFICACIÓN LFCS/LFCE
# Versión: 2.2 - Instalación robusta de paquetes
# ===================================================================================

# ── Configuración inicial ─────────────────────────────────────────────────────
set -o pipefail

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

# ===================================================================================
# FUNCIÓN: print_topology (sin cambios, omitida por brevedad)
# ===================================================================================
print_topology() {
  # ... (misma que antes) ...
}

# ===================================================================================
# FUNCIÓN: instalar_en_contenedor - Versión mejorada para instalación de paquetes
# ===================================================================================
instalar_en_contenedor() {
    local contenedor="$1"
    shift
    local paquetes=("$@")
    
    echo -e "→ Instalando paquetes en ${BOLD}$contenedor${NC}: ${paquetes[*]}"
    
    # Actualizar repositorios primero (con verificación)
    if ! docker exec "$contenedor" apt update -qq; then
        echo -e "  ${ROJO}✗ Error al actualizar repositorios${NC}"
        return 1
    fi
    
    # Instalar paquetes uno por uno para mejor diagnóstico
    local exitoso=0
    local fallido=0
    
    for pkg in "${paquetes[@]}"; do
        echo -ne "  Instalando ${pkg}... "
        if docker exec "$contenedor" apt install -y -qq "$pkg" &>/dev/null; then
            echo -e "${VERDE}✓ OK${NC}"
            ((exitoso++))
        else
            echo -e "${ROJO}✗ FALLO${NC}"
            ((fallido++))
        fi
    done
    
    echo -e "  ${VERDE}✓ $exitoso instalados${NC}, ${ROJO}✗ $fallido fallidos${NC}"
    [ $fallido -eq 0 ]
}

# ===================================================================================
# FUNCIÓN: instalar_con_barra - Versión mejorada para comandos del host
# ===================================================================================
instalar_con_barra() {
    local titulo="$1"
    shift
    local tareas=("$@")
    local total=${#tareas[@]}

    [[ -n "$titulo" ]] && echo -e "→ ${titulo}"
    echo ""

    for i in "${!tareas[@]}"; do
        local tarea="${tareas[$i]}"

        if [[ "$tarea" == *"::"* ]]; then
            local etiqueta="${tarea%%::*}"
            local cmd="${tarea##*::}"
        else
            local etiqueta="$tarea"
            local cmd="$tarea"
        fi

        # Ejecutar el comando
        if eval "$cmd" > /dev/null 2>&1; then
            local estado="${VERDE}✓${NC}"
        else
            local estado="${AMARILLO}⚠${NC}"
        fi

        local porcentaje=$(( (i + 1) * 100 / total ))
        local bloques_llenos=$(( (i + 1) * 20 / total ))
        local bloques_vacios=$(( 20 - bloques_llenos ))
        local barra_llena="" barra_vacia=""
        for ((b=0; b<bloques_llenos; b++)); do barra_llena+="██"; done
        for ((b=0; b<bloques_vacios; b++)); do barra_vacia+="░░"; done

        echo -ne "\r  ${VERDE}${BOLD}[${barra_llena}${GRIS}${barra_vacia}${VERDE}]${NC} ${BOLD}${porcentaje}%${NC} → ${etiqueta} ${estado}          "
    done

    echo -e "\n"
    echo -e "  ${VERDE}${BOLD}✔ ${titulo} completado — ${total} pasos ejecutados.${NC}"
    echo ""
}

# ===================================================================================
# FUNCIÓN: cleanup (sin cambios)
# ===================================================================================
cleanup() {
    echo -e "\n${AMARILLO}Limpiando recursos creados...${NC}"
    
    docker rm -f CORE-GW 2>/dev/null && echo -e "  ${ROJO}✗ Contenedor CORE-GW eliminado${NC}" || true
    rm -f /var/run/netns/CORE-GW 2>/dev/null && echo -e "  ${ROJO}✗ Symlink netns eliminado${NC}" || true
    ip link del v-gw-wan 2>/dev/null && echo -e "  ${ROJO}✗ Interfaz v-gw-wan eliminada${NC}" || true
    ip link del v-wan-gw 2>/dev/null && echo -e "  ${ROJO}✗ Interfaz v-wan-gw eliminada${NC}" || true
    
    echo -e "${VERDE}✔ Limpieza completada${NC}"
}

# ===================================================================================
# FUNCIÓN: test_conectividad (sin cambios)
# ===================================================================================
test_conectividad() {
    local test_name="$1"
    local test_cmd="$2"
    
    echo -ne "  Probando: ${test_name}... "
    
    if eval "$test_cmd" &>/dev/null; then
        echo -e "${VERDE}✓ OK${NC}"
        return 0
    else
        echo -e "${ROJO}✗ FALLO${NC}"
        return 1
    fi
}

# ===================================================================================
# FUNCIÓN: verificar_internet_desde_contenedor - Diagnóstico detallado
# ===================================================================================
verificar_conectividad_detallada() {
    echo -e "\n${CYAN}--- DIAGNÓSTICO DETALLADO ---${NC}"
    
    # Verificar rutas en el contenedor
    echo -e "\n${BOLD}Rutas en CORE-GW:${NC}"
    ip netns exec CORE-GW ip route show
    
    # Verificar resolución DNS
    echo -e "\n${BOLD}DNS en CORE-GW:${NC}"
    ip netns exec CORE-GW cat /etc/resolv.conf 2>/dev/null || echo "  No hay resolv.conf"
    
    # Agregar DNS si no existe
    if ! ip netns exec CORE-GW grep -q "8.8.8.8" /etc/resolv.conf 2>/dev/null; then
        echo -e "\n${AMARILLO}⚠ Configurando DNS en CORE-GW...${NC}"
        docker exec CORE-GW bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
    fi
    
    # Probar ping a gateway
    echo -e "\n${BOLD}Ping a gateway (172.16.255.1):${NC}"
    ip netns exec CORE-GW ping -c 2 -W 2 172.16.255.1
    
    # Probar ping a Internet
    echo -e "\n${BOLD}Ping a 8.8.8.8:${NC}"
    ip netns exec CORE-GW ping -c 2 -W 3 8.8.8.8
    
    # Verificar NAT
    echo -e "\n${BOLD}Reglas NAT en host:${NC}"
    iptables -t nat -L POSTROUTING -n -v | grep -E "(172.16.255.0|10.0.0.0)"
    
    echo ""
}

# ===================================================================================
# EJECUCIÓN PRINCIPAL
# ===================================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  
  echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║    LAB 001 - CORE-GW Y RED BASE         ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
  echo ""

  # Detectar interfaz WAN
  WAN_IF=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}')
  if [ -z "$WAN_IF" ]; then
      WAN_IF="eth0"
      echo -e "${AMARILLO}⚠ No se pudo detectar interfaz WAN, usando $WAN_IF${NC}"
  else
      echo -e "→ Interfaz WAN detectada: ${BOLD}$WAN_IF${NC}"
  fi
  echo ""

  # Limpiar antes de empezar
  cleanup

  # Instalación de Docker en el HOST
  instalar_con_barra "Instalando Docker en HOST" \
    "apt update::apt update -qq" \
    "dependencias::apt install -y -qq ca-certificates curl gnupg lsb-release" \
    "keyrings::install -m 0755 -d /etc/apt/keyrings" \
    "GPG key::curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg" \
    "repositorio::echo 'deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null" \
    "repo update::apt update -qq" \
    "docker-ce::apt install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" \
    "servicio Docker::systemctl start docker && systemctl enable docker"

  # Verificar Docker
  if systemctl is-active --quiet docker; then
    echo -e "${VERDE}✓ Docker service verificando${NC}"
  else
    echo -e "${ROJO}✗ Docker no está activo${NC}"
    exit 1
  fi

  # Descargar imagen Ubuntu
  if ! docker image inspect ubuntu:24.04 &> /dev/null; then
    echo -e "→ Descargando imagen ${BOLD}ubuntu:24.04${NC}..."
    docker pull ubuntu:24.04 > /dev/null
    echo -e "${VERDE}✓ Imagen descargada${NC}"
  else
    echo -e "→ Imagen ${BOLD}ubuntu:24.04${NC} ya existe."
  fi

  echo ""
  echo -e "${CYAN}==[ 1. CORE-GW: INFRAESTRUCTURA BASE CON DOCKER ]==${NC}"

  # Crear contenedor
  docker run -d --name CORE-GW --hostname core-gw --privileged --network none ubuntu:24.04 sleep infinity > /dev/null
  echo -e "${VERDE}✓ Contenedor CORE-GW creado${NC}"

  # Obtener PID y enlazar netns
  CORE_PID=$(docker inspect -f '{{.State.Pid}}' CORE-GW)
  echo -e "→ PID del contenedor CORE-GW: ${BOLD}$CORE_PID${NC}"
  mkdir -p /var/run/netns
  ln -sf /proc/$CORE_PID/ns/net /var/run/netns/CORE-GW 2>/dev/null || true
  
  if [ -L /var/run/netns/CORE-GW ]; then
    echo -e "${VERDE}✓ Namespace enlazado en /var/run/netns/CORE-GW${NC}"
  else
    echo -e "${ROJO}✗ Error al enlazar namespace${NC}"
  fi

  # Configurar /etc/hosts
  docker exec CORE-GW bash -c 'cat <<EOF > /etc/hosts
127.0.0.1       localhost
10.0.0.1        core-gw
EOF' 2>/dev/null
  docker exec CORE-GW hostname core-gw 2>/dev/null
  echo -e "${VERDE}✓ Configuración de identidad completada${NC}"

  # --- INSTALACIÓN DE PAQUETES EN CORE-GW (CORREGIDA) ---
  echo -e "${CYAN}==[ INSTALANDO PAQUETES EN CORE-GW ]==${NC}"
  
  # Primero, asegurar que apt funciona
  echo -e "→ Verificando conectividad a repositorios..."
  if docker exec CORE-GW ping -c 2 -W 3 8.8.8.8 &>/dev/null; then
    echo -e "  ${VERDE}✓ El contenedor tiene acceso a Internet${NC}"
  else
    echo -e "  ${AMARILLO}⚠ El contenedor NO tiene acceso a Internet todavía${NC}"
    echo -e "  Continuamos igual, pero las instalaciones pueden fallar..."
  fi
  
  # Actualizar repositorios (con reintentos)
  echo -e "→ Actualizando repositorios en CORE-GW..."
  for i in {1..3}; do
    if docker exec CORE-GW apt update -qq; then
      echo -e "  ${VERDE}✓ Repositorios actualizados${NC}"
      break
    else
      if [ $i -eq 3 ]; then
        echo -e "  ${ROJO}✗ No se pudieron actualizar los repositorios${NC}"
        echo -e "  Continuando con la instalación de todas formas..."
      else
        echo -e "  ${AMARILLO}⚠ Reintento $i/3...${NC}"
        sleep 2
      fi
    fi
  done
  
  # Instalar paquetes usando la función mejorada
  instalar_en_contenedor "CORE-GW" \
    "iproute2" \
    "iputils-ping" \
    "vim" \
    "tcpdump" \
    "dnsutils" \
    "curl" \
    "net-tools" \
    "iptables"

  # --- CONFIGURACIÓN DE RED (sin cambios) ---
  echo -e "${CYAN}==[ 2. CONFIGURACIÓN DE RED INTERNA ]==${NC}"
  
  ip netns exec CORE-GW ip link set lo up
  ip netns exec CORE-GW ip link add br0 type bridge 2>/dev/null || true
  ip netns exec CORE-GW ip link set br0 up
  ip netns exec CORE-GW ip addr add 10.0.0.1/24 dev br0 2>/dev/null || true
  echo -e "${VERDE}✓ Bridge br0 creado con IP 10.0.0.1/24${NC}"

  # Configurar enlace WAN
  echo -e "${CYAN}==[ 3. ENLACE WAN (CORE ↔ HOST) ]==${NC}"
  
  ip link add v-gw-wan type veth peer name v-wan-gw 2>/dev/null || true
  ip link set v-gw-wan netns CORE-GW 2>/dev/null || true
  ip link set v-wan-gw up
  ip netns exec CORE-GW ip link set v-gw-wan up
  
  ip addr add 172.16.255.1/30 dev v-wan-gw 2>/dev/null || true
  ip netns exec CORE-GW ip addr add 172.16.255.2/30 dev v-gw-wan 2>/dev/null || true
  
  ip route add 172.16.255.0/30 dev v-wan-gw metric 1000 2>/dev/null || true
  ip netns exec CORE-GW ip route del default 2>/dev/null || true
  ip netns exec CORE-GW ip route add default via 172.16.255.1 2>/dev/null || true
  
  echo -e "${VERDE}✓ Enlace WAN configurado: 172.16.255.1 (host) ↔ 172.16.255.2 (CORE)${NC}"

  # Configurar firewall
  echo -e "${CYAN}==[ 4. CONFIGURACIÓN KERNEL & FIREWALL ]==${NC}"
  
  sysctl -w net.ipv4.ip_forward=1 > /dev/null
  ip netns exec CORE-GW sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1 || true
  
  iptables -t nat -D POSTROUTING -s 172.16.255.0/30 -o $WAN_IF -j MASQUERADE 2>/dev/null || true
  iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o $WAN_IF -j MASQUERADE 2>/dev/null || true
  iptables -t nat -A POSTROUTING -s 172.16.255.0/30 -o $WAN_IF -j MASQUERADE
  iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o $WAN_IF -j MASQUERADE
  
  iptables -D FORWARD -s 172.16.255.0/30 -j ACCEPT 2>/dev/null || true
  iptables -D FORWARD -d 172.16.255.0/30 -j ACCEPT 2>/dev/null || true
  iptables -A FORWARD -s 172.16.255.0/30 -j ACCEPT
  iptables -A FORWARD -d 172.16.255.0/30 -j ACCEPT
  iptables -A FORWARD -s 10.0.0.0/24 -j ACCEPT
  iptables -A FORWARD -d 10.0.0.0/24 -j ACCEPT
  
  ip route add 10.0.0.0/24 via 172.16.255.2 metric 1000 2>/dev/null || true
  
  echo -e "${VERDE}✓ Firewall y rutas configurados${NC}"

  # Configurar DNS en el contenedor
  docker exec CORE-GW bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf' 2>/dev/null
  echo -e "${VERDE}✓ DNS configurado en CORE-GW${NC}"

  # Tests de conectividad
  echo -e "${CYAN}==[ 5. TEST DE CONECTIVIDAD ]==${NC}"
  echo ""

  TEST_EXITOS=0
  TEST_FALLOS=0

  test_conectividad "Host → CORE-GW (172.16.255.2)" "ping -c 2 -W 2 172.16.255.2" && ((TEST_EXITOS++)) || ((TEST_FALLOS++))
  test_conectividad "CORE-GW → Host (172.16.255.1)" "ip netns exec CORE-GW ping -c 2 -W 2 172.16.255.1" && ((TEST_EXITOS++)) || ((TEST_FALLOS++))
  
  # Test de Internet con diagnóstico si falla
  if test_conectividad "CORE-GW → Internet (8.8.8.8)" "ip netns exec CORE-GW ping -c 2 -W 3 8.8.8.8"; then
    ((TEST_EXITOS++))
  else
    ((TEST_FALLOS++))
    # Diagnóstico automático
    verificar_conectividad_detallada
  fi
  
  test_conectividad "Bridge LAN (br0 - 10.0.0.1/24)" "ip netns exec CORE-GW ip addr show br0 | grep -q '10.0.0.1'" && ((TEST_EXITOS++)) || ((TEST_FALLOS++))

  echo ""
  echo -e "  ${BOLD}Resumen:${NC} ${VERDE}$TEST_EXITOS exitosos${NC}, ${ROJO}$TEST_FALLOS fallos${NC}"
  echo ""

  if [ $TEST_FALLOS -eq 0 ]; then
    echo -e "${VERDE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${VERDE}║    LAB 001 COMPLETADO EXITOSAMENTE     ║${NC}"
    echo -e "${VERDE}╚══════════════════════════════════════════╝${NC}"
  else
    echo -e "${AMARILLO}╔══════════════════════════════════════════╗${NC}"
    echo -e "${AMARILLO}║    LAB 001 COMPLETADO CON ADVERTENCIAS ║${NC}"
    echo -e "${AMARILLO}╚══════════════════════════════════════════╝${NC}"
  fi

  # Mostrar topología
  print_topology
  
  echo -e "${GRIS}───────────────────────────────────────────────────────${NC}"
  echo -e "${GRIS}Para acceder al CORE-GW: ip netns exec CORE-GW bash${NC}"
  echo -e "${GRIS}Para diagnóstico: ip netns exec CORE-GW ping 8.8.8.8${NC}"
  echo ""
fi