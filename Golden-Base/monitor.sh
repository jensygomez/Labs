#!/usr/bin/env bash
# ===================================================================================
# LAB MONITOR — Golden Base (Versión Minimalista Integrada)
# ===================================================================================

# ── Intervalo de chequeo (segundos) ──────────────────────────────────────────
INTERVALO=5

# ── Nodos de la topología ─────────────────────────────────────────────────────
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

# ── Tests de conectividad ─────────────────────────────────────────────────────
TESTS=(
    "CORE-GW:PC1-RH:10.0.0.21"
    "CORE-GW:PC2-RH:10.0.0.22"
    "CORE-GW:PC3-RH:10.0.0.23"
    "PC1-RH:CORE-GW:10.0.0.1"
    "PC1-RH:PC2-RH:10.0.0.22"
    "PC1-RH:PC3-RH:10.0.0.23"
    "PC1-RH:Internet:8.8.8.8"
    "PC1-RH:SRV-LDAP:10.0.0.11"
)

# ===================================================================================
# NO MODIFICAR — lógica del monitor
# ===================================================================================

VERDE='\033[0;32m'
ROJO='\033[0;31m'
CYAN='\033[0;36m'
GRIS='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m'

ESTADO_ANTERIOR=""

contenedor_activo() {
    docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$1"
}

ping_ok() {
    local ORIGEN="$1"
    local IP="$2"
    docker exec "$ORIGEN" ping -c1 -W1 "$IP" &>/dev/null
}

capturar_estado() {
    local STATE=""
    for nodo in "${NODOS[@]}"; do
        local NAME="${nodo%%:*}"
        contenedor_activo "$NAME" && STATE+="$NAME:up " || STATE+="$NAME:down "
    done
    for test in "${TESTS[@]}"; do
        local ORIGEN="${test%%:*}"
        local REST="${test#*:}"
        local LABEL="${REST%%:*}"
        local IP="${REST##*:}"
        if contenedor_activo "$ORIGEN"; then
            ping_ok "$ORIGEN" "$IP" && STATE+="$ORIGEN>$LABEL:ok " || STATE+="$ORIGEN>$LABEL:fail "
        else
            STATE+="$ORIGEN>$LABEL:skip "
        fi
    done
    echo "$STATE"
}

c() {
    local NAME="$1"
    local LABEL="$2"
    if contenedor_activo "$NAME"; then
        printf "${VERDE}%s${NC}" "$LABEL"
    else
        printf "${ROJO}%s${NC}" "$LABEL"
    fi
}

p() {
    local ORIGEN="$1"
    local DESTINO_IP="$2"
    local LABEL="$3"
    if contenedor_activo "$ORIGEN" && ping_ok "$ORIGEN" "$DESTINO_IP"; then
        printf "${VERDE}%s${NC}" "$LABEL"
    else
        printf "${ROJO}%s${NC}" "$LABEL"
    fi
}

dibujar_topologia() {
    local CORE_GW; CORE_GW=$(c "CORE-GW"  "CORE-GW ")
    local NS__RH_; NS__RH_=$(c "NS-RH"    "NS-RH   ")
    local NS_SRV_; NS_SRV_=$(c "NS-SRV"   "NS-SRV  ")
    local NS_INF_; NS_INF_=$(c "NS-INFRA" "NS-INFRA")
    local NS_SYS_; NS_SYS_=$(c "NS-SYS"   "NS-SYS  ")
    local PC1_RH_; PC1_RH_=$(c "PC1-RH"   "PC1 .21 ")
    local PC2_RH_; PC2_RH_=$(c "PC2-RH"   "PC2 .22 ")
    local PC3_RH_; PC3_RH_=$(c "PC3-RH"   "PC3 .23 ")
    local SV_LDAP; SV_LDAP=$(c "SRV-LDAP" "LDAP .11")
    local SV__FS_; SV__FS_=$(c "SRV-FS"   "FS   .12")
    local SV_DNS_; SV_DNS_=$(c "SRV-DNS"  "DNS  .2 ")
    local SV_DHCP; SV_DHCP=$(c "SRV-DHCP" "DHCP .3 ")
    local PC1_SYS; PC1_SYS=$(c "PC1-SYS"  "PC1   31")

    # Variables de Test (Guiones bajos para evitar errores de Bash)
    local PC_LDP; PC_LDP=$(p "PC1-RH" "10.0.0.11" "LDAP  11")
    local PC_GW_; PC_GW_=$(p "PC1-RH" "10.0.0.1"  "GW-OK   ")
    local PC_WAN; PC_WAN=$(p "PC1-RH" "8.8.8.8"   "INTERNET")

    echo -e "               ${CYAN}┌───────────────────────────────────────────────────────┐${NC}"
    echo -e "               ${CYAN}│                      INTERNET                         │${NC}"
    echo -e "               ${CYAN}│                      (8.8.8.8)                        │${NC}"
    echo -e "               ${CYAN}└──────────────────────────┬────────────────────────────┘${NC}"
    echo -e "                                          │"  
    echo -e "                     ┌────────────────────┴─────────────────────┐"
    echo -e "                     │             HOST (tu PC/VM)              │"
    echo -e "                     │       172.16.255.1/30 (v-wan-gw)         │"
    echo -e "                     └────────────────────┬─────────────────────┘"
    echo -e "                                          │"
    echo -e "                                          │ veth pair"
    echo -e "                                          │"
    echo -e "               ┌──────────────────────────┴────────────────────────────┐"
    echo -e "               │                        $CORE_GW                       │"
    echo -e "               │            ┌─────────────────────────────┐            │"
    echo -e "               │            │  br0:      0.0.0.1/24       │            │"
    echo -e "               │            │  v-gw-wan: 172.16.255.2/30  │            │"
    echo -e "               │            └─────────────────────────────┘            │"
    echo -e "               └──────────────────────────┬────────────────────────────┘"
    echo -e "                                          │"
    echo -e "          ┌────────────────────┌──────────┘─────────┌────────────────────┐"
    echo -e "          │                    │                    │                    │"
    echo -e " ┌────────┴────────┐  ┌────────┴────────┐  ┌────────┴────────┐  ┌────────┴────────┐"
    echo -e " │     $NS_SRV_    │  │     $NS__RH_    │  │     $NS_SYS_    │  │    $NS_INF_     │"
    echo -e " │  (contenedor)   │  │   (contenedor)  │  │   (contenedor)  │  │  (contenedor)   │"
    echo -e " │                 │  │                 │  │                 │  │                 │"
    echo -e " │  ┌──────────┐   │  │  ┌──────────┐   │  │  ┌──────────┐   │  │  ┌──────────┐   │"
    echo -e " │  │ br-srv   │   │  │  │  br-rh   │   │  │  │  br-sys  │   │  │  |  br-inf  │   │"
    echo -e " │  │(switch L2│   │  │  │  (L2)    │   │  │  │   (L2)   │   │  │  |   (L2)   │   │"
    echo -e " │  └────┬─────┘   │  │  └────┬─────┘   │  │  └────┬─────┘   │  |  └─────┬────┘   │"
    echo -e " └───────┼─────────┘  └───────┼─────────┘  └───────┼─────────┘  └────────┼────────┘"
    echo -e "         │                    │                    │                     │"
    echo -e "  ┌──────┴──────┐      ┌──────┴──────┐      ┌──────┴──────┐       ┌──────┴──────┐"
    echo -e "  │  $SV_LDAP   │      │  $PC1_RH_   │      │  $PC1_SYS   │       │  $SV_DNS_   │"
    echo -e "  │  10.0.0.11  │      │  10.0.0.21  │      │  10.0.0.31  │       │  10.0.0.2   │"
    echo -e "  |             |      | $PC_GW_    |      |             |       |             |"
    echo -e "  |             |      | $PC_WAN    |      |             |       |             | "
    echo -e "  |             |      | $PC_LDP    |      |             |       |             | "
    echo -e "  ├─────────────┤      ├─────────────┤      └─────────────┘       ├─────────────┤"
    echo -e "  │  $SV__FS_   │      │  $PC2_RH_   │                            │  $SV_DHCP   │"
    echo -e "  │  10.0.0.12  │      │  10.0.0.22  │                            │  10.0.0.3   │"
    echo -e "  └─────────────┘      ├─────────────┤                            └─────────────┘"
    echo -e "                       │  $PC3_RH_   │"
    echo -e "                       │  10.0.0.23  │"
    echo -e "                       └─────────────┘"
}

dibujar() {
    local TIMESTAMP=$(date '+%H:%M:%S')
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         LAB MONITOR — DASHBOARD INTEGRADO        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo -e "\n${BOLD}  TOPOLOGÍA EN TIEMPO REAL${NC}"
    echo -e "  ${GRIS}──────────────────────────────────────────────────${NC}"
    dibujar_topologia
    echo -e "\n  ${VERDE}● activo${NC}  ${ROJO}● inactivo/fail${NC}  |  Actualizado: $TIMESTAMP"
    echo -e "  ${GRIS}Refresco automático solo en cambios de estado. Ctrl+C para salir.${NC}"
}

# ── Arranque ──────────────────────────────────────────────────────────────────
ESTADO_ACTUAL=$(capturar_estado)
dibujar
ESTADO_ANTERIOR="$ESTADO_ACTUAL"

while true; do
    sleep "$INTERVALO"
    ESTADO_ACTUAL=$(capturar_estado)
    if [ "$ESTADO_ACTUAL" != "$ESTADO_ANTERIOR" ]; then
        dibujar
        ESTADO_ANTERIOR="$ESTADO_ACTUAL"
    fi
done