#!/usr/bin/env bash
# ===================================================================================
# LAB MONITOR — Golden Base
# ===================================================================================
# CÓMO PERSONALIZAR:
#   - Agregar nodos:  añade línea a NODOS  →  "NOMBRE:IP"  (IP vacía = switch L2)
#   - Agregar tests:  añade línea a TESTS  →  "ORIGEN:DESTINO:IP"
#   - Cambiar intervalo: modifica INTERVALO
#   - El código debajo de "NO MODIFICAR" no necesita tocarse nunca
# ===================================================================================

# ── Intervalo de chequeo (segundos) ──────────────────────────────────────────
INTERVALO=5

# ── Nodos de la topología ─────────────────────────────────────────────────────
# Formato: "NOMBRE_CONTENEDOR:IP"   (IP vacía = switch L2, no se hace ping)
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
# Formato: "CONTENEDOR_ORIGEN:LABEL_DESTINO:IP_DESTINO"
# El ping sale desde dentro del CONTENEDOR_ORIGEN hacia IP_DESTINO
# Agrega, quita o modifica líneas libremente
TESTS=(
    "CORE-GW:PC1-RH:10.0.0.21"
    "CORE-GW:PC2-RH:10.0.0.22"
    "CORE-GW:PC3-RH:10.0.0.23"
    "PC1-RH:CORE-GW:10.0.0.1"
    "PC1-RH:PC2-RH:10.0.0.22"
    "PC1-RH:PC3-RH:10.0.0.23"
    "PC1-RH:Internet:8.8.8.8"
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

    # Estado de cada nodo
    for nodo in "${NODOS[@]}"; do
        local NAME="${nodo%%:*}"
        contenedor_activo "$NAME" && STATE+="$NAME:up " || STATE+="$NAME:down "
    done

    # Resultado de cada test
    for test in "${TESTS[@]}"; do
        local ORIGEN="${test%%:*}"
        local REST="${test#*:}"
        local LABEL="${REST%%:*}"
        local IP="${REST##*:}"
        if contenedor_activo "$ORIGEN"; then
            ping_ok "$ORIGEN" "$IP" \
                && STATE+="$ORIGEN>$LABEL:ok " \
                || STATE+="$ORIGEN>$LABEL:fail "
        else
            STATE+="$ORIGEN>$LABEL:skip "
        fi
    done

    echo "$STATE"
}

# Colorea label según si el contenedor está activo
c() {
    local NAME="$1"
    local LABEL="$2"
    if contenedor_activo "$NAME"; then
        printf "${VERDE}%s${NC}" "$LABEL"
    else
        printf "${ROJO}%s${NC}" "$LABEL"
    fi
}

dibujar_topologia() {
    # Todos los labels tienen exactamente 8 caracteres visibles
    # Así puedes dibujar el ASCII sabiendo que $VAR = 8 chars siempre
    # Variable = 7 chars, Label = 8 chars visibles en terminal
    local CORE_GW; CORE_GW=$(c "CORE-GW"  "CORE-GW ")  # 8
    local NS__RH_; NS__RH_=$(c "NS-RH"    "NS-RH   ")  # 8
    local NS_SRV_; NS_SRV_=$(c "NS-SRV"   "NS-SRV  ")  # 8
    local NS_INF_; NS_INF_=$(c "NS-INFRA" "NS-INFRA")  # 8
    local NS_SYS_; NS_SYS_=$(c "NS-SYS"   "NS-SYS  ")  # 8
    local PC1_RH_; PC1_RH_=$(c "PC1-RH"   "PC1 .21 ")  # 8
    local PC2_RH_; PC2_RH_=$(c "PC2-RH"   "PC2 .22 ")  # 8
    local PC3_RH_; PC3_RH_=$(c "PC3-RH"   "PC3 .23 ")  # 8
    local SV_LDAP; SV_LDAP=$(c "SRV-LDAP" "LDAP .11")  # 8
    local SV__FS_; SV__FS_=$(c "SRV-FS"   "FS   .12")  # 8
    local SV_DNS_; SV_DNS_=$(c "SRV-DNS"  "DNS  .2 ")  # 8
    local SV_DHCP; SV_DHCP=$(c "SRV-DHCP" "DHCP .3 ")  # 8
    local PC1_SYS; PC1_SYS=$(c "PC1-SYS"  "PC1 .31 ")  # 8

    echo -e "               ${CYAN}┌───────────────────────────────────────────────────────┐${NC}              "
    echo -e "               ${CYAN}│                      INTERNET                         │${NC}              "
    echo -e "               ${CYAN}│                      (8.8.8.8)                        │${NC}              "
    echo -e "               ${CYAN}└──────────────────────────┬────────────────────────────┘${NC}              "
    echo -e "                                          │                                                 "  
    echo -e "                     ┌────────────────────┴─────────────────────┐                           "
    echo -e "                     │             HOST (tu PC/VM)              │                           "
    echo -e "                     │       172.16.255.1/30 (v-wan-gw)         │                           "
    echo -e "                     └────────────────────┬─────────────────────┘                           "
    echo -e "                                          │                                                 "
    echo -e "                                          │ veth pair                                       "
    echo -e "                                          │                                                 "
    echo -e "               ┌──────────────────────────┴────────────────────────────┐                     "
    echo -e "               │                        $CORE_GW                       │                     "
    echo -e "               │            ┌─────────────────────────────┐            │                     "
    echo -e "               │            │  br0:      0.0.0.1/24       │            │                     "
    echo -e "               │            │  v-gw-wan: 172.16.255.2/30  │            │                     "
    echo -e "               │            └─────────────────────────────┘            │                     "
    echo -e "               └──────────────────────────┬────────────────────────────┘                     "
    echo -e "                                          │                                                 "
    echo -e "          ┌────────────────────┌──────────┘─────────┌────────────────────┐               "
    echo -e "          │                    │                    │                    │               "
    echo -e " ┌────────┴────────┐  ┌────────┴────────┐  ┌────────┴────────┐  ┌────────┴────────┐      "
    echo -e " │     $NS_SRV_    │  │     $NS__RH_    │  │     $NS_SYS_    │  │    $NS_INF_     │      "
    echo -e " │  (contenedor)   │  │   (contenedor)  │  │   (contenedor)  │  │  (contenedor)   │      "
    echo -e " │                 │  │                 │  │                 │  │                 │      "
    echo -e " │  ┌──────────┐   │  │  ┌──────────┐   │  │  ┌──────────┐   │  │  ┌──────────┐   │      "
    echo -e " │  │ br-srv   │   │  │  │  br-rh   │   │  │  │  br-sys  │   │  │  |  br-inf  │   │      "
    echo -e " │  │(switch L2│   │  │  │  (L2)    │   │  │  │   (L2)   │   │  │  |   (L2)   │   │      "
    echo -e " │  └────┬─────┘   │  │  └────┬─────┘   │  │  └────┬─────┘   │  |  └─────┬────┘   │      "
    echo -e " └───────┼─────────┘  └───────┼─────────┘  └───────┼─────────┘  └────────┼────────┘      "
    echo -e "         │                    │                    │                     │              "
    echo -e "  ┌──────┴──────┐      ┌──────┴──────┐      ┌──────┴──────┐       ┌──────┴──────┐        "
    echo -e "  │  $SV_LDAP   │      │  $PC1_RH_   │      │  $PC1_SYS   │       │  $SV_DNS_   │        "
    echo -e "  │  10.0.0.11  │      │  10.0.0.21  │      │  10.0.0.31  │       │  10.0.0.2   │        "
    echo -e "  ├─────────────┤      ├─────────────┤      └─────────────┘       ├─────────────┤        "
    echo -e "  │  $SV__FS_   │      │  $PC2_RH_   │                            │  $SV_DHCP   │        "
    echo -e "  │  10.0.0.12  │      │  10.0.0.22  │                            │  10.0.0.3   │        "
    echo -e "  └─────────────┘      ├─────────────┤                            └─────────────┘        "
    echo -e "                       │  $PC3_RH_   │                                                      "
    echo -e "                       │  10.0.0.23  │                                                      "
    echo -e "                       └─────────────┘                                                      "


}

dibujar_nodos() {
    echo -e "  ${CYAN}$(printf '%-14s' 'CONTENEDOR')  $(printf '%-15s' 'IP')  ESTADO${NC}"
    echo -e "  ${GRIS}──────────────────────────────────────────────────${NC}"
    for nodo in "${NODOS[@]}"; do
        local NAME="${nodo%%:*}"
        local IP="${nodo##*:}"
        if contenedor_activo "$NAME"; then
            local ICONO="${VERDE}●${NC}"
            local NOMBRE="${VERDE}$(printf '%-14s' "$NAME")${NC}"
            local IP_STR="${GRIS}$(printf '%-15s' "${IP:--}")${NC}"
            local ESTADO="${IP:+${GRIS}activo${NC}}"
            [ -z "$IP" ] && ESTADO="${GRIS}switch L2${NC}"
        else
            local ICONO="${ROJO}○${NC}"
            local NOMBRE="${GRIS}$(printf '%-14s' "$NAME")${NC}"
            local IP_STR="${GRIS}$(printf '%-15s' '-')${NC}"
            local ESTADO="${GRIS}inactivo${NC}"
        fi
        echo -e "  $ICONO  $NOMBRE  $IP_STR  $ESTADO"
    done
}

dibujar_tests() {
    echo -e "  ${CYAN}$(printf '%-20s' 'ORIGEN → DESTINO')  RESULTADO${NC}"
    echo -e "  ${GRIS}──────────────────────────────────────────────────${NC}"
    for test in "${TESTS[@]}"; do
        local ORIGEN="${test%%:*}"
        local REST="${test#*:}"
        local LABEL="${REST%%:*}"
        local IP="${REST##*:}"
        local RUTA="$(printf '%-20s' "$ORIGEN → $LABEL")"
        if ! contenedor_activo "$ORIGEN"; then
            echo -e "  ${GRIS}$RUTA  contenedor inactivo${NC}"
        elif ping_ok "$ORIGEN" "$IP"; then
            echo -e "  ${VERDE}$RUTA  ping ✔  ($IP)${NC}"
        else
            echo -e "  ${ROJO}$RUTA  ping ✘  ($IP)${NC}"
        fi
    done
}

dibujar() {
    local TIMESTAMP
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         LAB MONITOR — Golden Base                ║${NC}"
    echo -e "${CYAN}║         $TIMESTAMP                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"

    echo -e "\n${BOLD}  TOPOLOGÍA${NC}"
    echo -e "  ${GRIS}──────────────────────────────────────────────────${NC}"
    dibujar_topologia
    echo -e "  ${VERDE}● activo${NC}   ${ROJO}● inactivo${NC}"

    echo -e "\n${BOLD}  NODOS${NC}"
    dibujar_nodos

    echo -e "\n${BOLD}  TESTS DE CONECTIVIDAD${NC}"
    echo -e "  ${GRIS}──────────────────────────────────────────────────${NC}"
    dibujar_tests

    echo -e "\n  ${GRIS}Actualizado: $TIMESTAMP — refresca solo si hay cambios — Ctrl+C para salir${NC}"
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