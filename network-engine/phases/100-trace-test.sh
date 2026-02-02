run_phase() {
    # Definir colores localmente
    G='\033[0;32m'
    B='\033[0;34m'
    Y='\033[1;33m'
    R='\033[0;31m'  # Rojo para errores/warnings
    NC='\033[0m' 
    BOLD='\033[1m'

    echo -e "\n${BOLD}====================================================${NC}"
    echo -e "${BOLD}[FASE 100] TEST DE TRAZABILIDAD DINÁMICA${NC}"
    echo -e "${BOLD}====================================================${NC}"

    check_node() {
        local ns=$1
        local label=$2
        local color=$3
        
        # tcpdump sin límite de paquetes, pero con timeout externo
        # Filtramos solo ICMP echo request/reply para reducir ruido
        sudo timeout 10 ip netns exec "$ns" tcpdump -l -nn -i any 'icmp[icmptype] = icmp-echo or icmp[icmptype] = icmp-echoreply' 2>/dev/null | 
        while read -r line; do
            if [[ "$line" =~ "echo request" ]]; then
                echo -e "  ${color}[➡ REQ]${NC} Pasando por: ${BOLD}$label${NC} ── $line"
            elif [[ "$line" =~ "echo reply" ]]; then
                echo -e "  ${color}[⬅ REP]${NC} Retornando por: ${BOLD}$label${NC} ── $line"
            fi
        done &
    }

    echo -e "🔍 ${Y}Iniciando sensores (timeout 10s cada uno)...${NC}"
    
    # Lanzar los 4 sensores en background
    check_node "$NS_CORE_SVC"  "CORE-SVC (Origen)"   "$B"
    check_node "$NS_CORE_EDGE" "CORE-EDGE (Tránsito)" "$G"
    check_node "$NS_EDGE_1"    "EDGE-1 (Gateway)"     "$G"
    check_node "$NS_INTERNET"  "INTERNET (Destino)"   "$Y"  # Amarillo para destino

    sleep 1.5  # Dar tiempo a que tcpdump arranque y escuche

    echo -e "🚀 ${Y}Lanzando PING: VLAN 10 -> Internet (203.0.113.2)${NC}"
    echo -e "----------------------------------------------------"

    # Ping con más margen de espera
    sudo ip netns exec "$NS_CORE_SVC" ping -c 1 -W 3 -I eth1.10 203.0.113.2 > /dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        echo -e "  ${G}Ping exitoso (exit code 0)${NC}"
    else
        echo -e "  ${R}Ping falló (exit code $?)${NC} → revisar rutas/NAT/firewall"
    fi

    # Esperar un poco más para que salgan los últimos mensajes de los sensores
    sleep 4

    echo -e "----------------------------------------------------"
    echo -e "✅ ${BOLD}Test completado.${NC}"
    echo -e "   (Si no ves REQ/REP en todos los nodos, el tráfico se pierde en algún punto)"
}