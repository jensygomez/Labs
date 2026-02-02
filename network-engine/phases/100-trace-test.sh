#!/bin/bash

run_phase() {
    # Definir colores localmente
    G='\033[0;32m'
    B='\033[0;34m'
    Y='\033[1;33m'
    NC='\033[0m' 
    BOLD='\033[1m'

    echo -e "\n${BOLD}====================================================${NC}"
    echo -e "${BOLD}[FASE 100] TEST DE TRAZABILIDAD DINÁMICA${NC}"
    echo -e "${BOLD}====================================================${NC}"

    check_node() {
        local ns=$1
        local label=$2
        local color=$3
        # Escuchamos request y reply
        sudo ip netns exec "$ns" tcpdump -l -nn -i any icmp -c 2 2>/dev/null | while read line; do
            if [[ "$line" == *"echo request"* ]]; then
                echo -e "  ${color}[➡ REQ]${NC} Pasando por: ${BOLD}$label${NC}"
            elif [[ "$line" == *"echo reply"* ]]; then
                echo -e "  ${color}[⬅ REP]${NC} Retornando por: ${BOLD}$label${NC}"
            fi
        done &
    }

    echo -e "🔍 ${Y}Iniciando sensores...${NC}"
    check_node "$NS_CORE_SVC"  "CORE-SVC (Origen)"  "$B"
    check_node "$NS_CORE_EDGE" "CORE-EDGE (Tránsito)" "$G"
    check_node "$NS_EDGE_1"    "EDGE-1 (Gateway)"    "$G"
    check_node "$NS_INTERNET"  "INTERNET (Destino)"   "$G"

    sleep 2 # Esperar a que tcpdump se enganche bien

    echo -e "🚀 ${Y}Lanzando PING: VLAN 10 -> Internet (203.0.113.2)${NC}"
    echo -e "----------------------------------------------------"

    # Lanzamos el ping
    sudo ip netns exec "$NS_CORE_SVC" ping -c 1 -W 1 -I eth1.10 203.0.113.2 > /dev/null 2>&1

    # Esperamos a que los procesos de tcpdump terminen su salida
    wait
    
    echo -e "----------------------------------------------------"
    echo -e "✅ ${BOLD}Test completado con éxito.${NC}"
}