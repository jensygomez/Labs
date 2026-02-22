#!/usr/bin/env bash
# ===================================================================================
# LAB MONITOR — Golden Base
# Uso: bash monitor.sh
# Abre en una terminal separada mientras trabajas en el lab
# ===================================================================================

# ── Colores ───────────────────────────────────────────────────────────────────
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
CYAN='\033[0;36m'
GRIS='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m'

INTERVALO=3  # segundos entre refresco

# ── Nodos del lab con sus IPs ─────────────────────────────────────────────────
# Formato: "NOMBRE_CONTENEDOR:IP_PARA_PING"
# IP vacía = solo verifica si el contenedor existe
NODOS=(
    "CORE-GW:10.0.0.1"
    "NS-RH:"
    "PC1-RH:10.0.0.21"
    "PC2-RH:10.0.0.22"
    "PC3-RH:10.0.0.23"
    "NS-SRV:"
    "SRV-LDAP:10.0.0.11"
    "SRV-FS:10.0.0.12"
    "NS-INFRA:"
    "SRV-DNS:10.0.0.2"
    "SRV-DHCP:10.0.0.3"
    "NS-SYS:"
    "PC1-SYS:10.0.0.31"
)

# ── Helpers ───────────────────────────────────────────────────────────────────
contenedor_activo() {
    docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$1"
}

ping_ok() {
    # Ping desde el host hacia la IP — timeout 1s, 1 paquete
    ping -c1 -W1 "$1" &>/dev/null
}

estado_nodo() {
    local NAME="$1"
    local IP="$2"

    local DOCKER_OK=false
    local PING_OK=false
    local PING_STR="  n/a  "

    contenedor_activo "$NAME" && DOCKER_OK=true

    if [ -n "$IP" ] && $DOCKER_OK; then
        if ping_ok "$IP"; then
            PING_OK=true
            PING_STR="${VERDE} ping ✔${NC}"
        else
            PING_STR="${ROJO} ping ✘${NC}"
        fi
    fi

    # Icono y color del nombre
    if $DOCKER_OK; then
        local ICONO="${VERDE}●${NC}"
        local NOMBRE="${VERDE}$(printf '%-12s' "$NAME")${NC}"
    else
        local ICONO="${ROJO}○${NC}"
        local NOMBRE="${GRIS}$(printf '%-12s' "$NAME")${NC}"
    fi

    # IP formateada
    local IP_STR
    if [ -n "$IP" ]; then
        IP_STR=$(printf '%-14s' "$IP")
    else
        IP_STR=$(printf '%-14s' "(switch L2)")
    fi

    echo -e "  $ICONO  $NOMBRE  ${GRIS}$IP_STR${NC}  $PING_STR"
}

# ── Topología visual compacta ─────────────────────────────────────────────────
dibujar_topologia() {
    # Colores por estado
    c() {
        # c NOMBRE LABEL
        if contenedor_activo "$1"; then
            echo -e "${VERDE}$2${NC}"
        else
            echo -e "${ROJO}$2${NC}"
        fi
    }

    local CORE; CORE=$(c "CORE-GW"  "CORE-GW")
    local NSRH; NSRH=$(c "NS-RH"   "NS-RH  ")
    local NSSRV; NSSRV=$(c "NS-SRV" "NS-SRV ")
    local NSINF; NSINF=$(c "NS-INFRA" "NS-INFRA")
    local NSSYS; NSSYS=$(c "NS-SYS" "NS-SYS ")
    local PC1; PC1=$(c "PC1-RH"   ".21")
    local PC2; PC2=$(c "PC2-RH"   ".22")
    local PC3; PC3=$(c "PC3-RH"   ".23")
    local LDAP; LDAP=$(c "SRV-LDAP" ".11")
    local FS;   FS=$(c "SRV-FS"   ".12")
    local DNS;  DNS=$(c "SRV-DNS"  ".2 ")
    local DHCP; DHCP=$(c "SRV-DHCP" ".3 ")
    local SYS1; SYS1=$(c "PC1-SYS" ".31")

    echo -e "                    ${CYAN}INTERNET${NC}"
    echo -e "                        │"
    echo -e "                   HOST (172.16.255.1)"
    echo -e "                        │"
    echo -e "               ┌────────┴────────┐"
    echo -e "               │    $CORE    │  br0:10.0.0.1"
    echo -e "               └──┬──────┬──┬──┬─┘"
    echo -e "            ┌─────┘  ┌───┘  │  └──────┐"
    echo -e "         $NSSRV   $NSRH  $NSSYS   $NSINF"
    echo -e "          │        │  │  │    │      │    │"
    echo -e "        $LDAP   $PC1 $PC2 $PC3  $SYS1  $DNS $DHCP"
    echo -e "        $FS"
}

# ── Stats de contenedores activos ─────────────────────────────────────────────
mostrar_stats() {
    local STATS
    STATS=$(docker stats --no-stream --format "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null)
    if [ -n "$STATS" ]; then
        echo -e "  ${CYAN}$(printf '%-14s' CONTENEDOR')  $(printf '%-8s' 'CPU')  MEM${NC}"
        echo -e "  ${GRIS}─────────────────────────────────────────${NC}"
        while IFS=$'\t' read -r name cpu mem; do
            printf "  %-14s  %-8s  %s\n" "$name" "$cpu" "$mem"
        done <<< "$STATS"
    else
        echo -e "  ${GRIS}Sin contenedores activos.${NC}"
    fi
}

# ── Loop principal ────────────────────────────────────────────────────────────
while true; do
    clear

    # Header
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         LAB MONITOR — Golden Base                   ║${NC}"
    echo -e "${CYAN}║         $(date '+%Y-%m-%d %H:%M:%S')   refresco: ${INTERVALO}s          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"

    # Topología
    echo -e "\n${BOLD}  TOPOLOGÍA${NC}"
    echo -e "  ${GRIS}─────────────────────────────────────────${NC}"
    dibujar_topologia

    # Estado por nodo
    echo -e "\n${BOLD}  NODOS${NC}"
    echo -e "  ${GRIS}─────────────────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}$(printf '%-16s' 'CONTENEDOR')  $(printf '%-14s' 'IP')  CONECTIVIDAD${NC}"
    echo -e "  ${GRIS}─────────────────────────────────────────────────────${NC}"
    for nodo in "${NODOS[@]}"; do
        NAME="${nodo%%:*}"
        IP="${nodo##*:}"
        estado_nodo "$NAME" "$IP"
    done

    # Stats CPU/MEM
    echo -e "\n${BOLD}  RECURSOS${NC}"
    echo -e "  ${GRIS}─────────────────────────────────────────${NC}"
    mostrar_stats

    echo -e "\n  ${GRIS}Ctrl+C para salir${NC}"

    sleep "$INTERVALO"
done