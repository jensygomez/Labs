#!/bin/bash

# Definir colores localmente para evitar errores de "unbound variable"
G='\033[0;32m'
B='\033[0;34m'
R='\033[0;31m'
Y='\033[1;33m'
NC='\033[0m' 
BOLD='\033[1m'

echo -e "\n${BOLD}====================================================${NC}"
echo -e "${BOLD}[FASE 100] TEST DE TRAZABILIDAD DINÁMICA${NC}"
echo -e "${BOLD}====================================================${NC}"

# Función para monitorear en segundo plano de forma silenciosa
check_node() {
    local ns=$1
    local label=$2
    local color=$3
    # Escuchamos solo 1 paquete ICMP (request o reply)
    sudo ip netns exec "$ns" tcpdump -l -nn -i any icmp -c 2 2>/dev/null | while read line; do
        if [[ "$line" == *"echo request"* ]]; then
            echo -e "  ${color}[➡ REQ]${NC} Pasando por: ${BOLD}$label${NC}"
        elif [[ "$line" == *"echo reply"* ]]; then
            echo -e "  ${color}[⬅ REP]${NC} Retornando por: ${BOLD}$label${NC}"
        fi
    done &
}

echo -e "🔍 ${Y}Iniciando sensores en los nodos...${NC}"

# Lanzamos los sensores usando las variables del lab.conf
check_node "$NS_CORE_SVC"  "CORE-SVC (Origen)"  "$B"
check_node "$NS_CORE_EDGE" "CORE-EDGE (Tránsito)" "$G"
check_node "$NS_EDGE_1"    "EDGE-1 (Gateway)"    "$G"
check_node "$NS_INTERNET"  "INTERNET (Destino)"   "$R"

sleep 2 # Tiempo para que tcpdump se estabilice

echo -e "🚀 ${Y}Lanzando PING de prueba: VLAN 10 -> Internet (203.0.113.2)${NC}"
echo -e "----------------------------------------------------"

# Ejecutamos el ping con un timeout corto
sudo ip netns exec "$NS_CORE_SVC" ping -c 1 -W 2 -I eth1.10 203.0.113.2 > /dev/null 2>&1

# Esperar un poco a que los tcpdumps terminen de imprimir
sleep 2

echo -e "----------------------------------------------------"
echo -e "✅ ${BOLD}Test finalizado.${NC}"