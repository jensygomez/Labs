#!/bin/bash

echo -e "\n${BOLD}[FASE 100] Verificación Dinámica de Flujo${NC}"

# Función interna para capturar un paquete de prueba
check_flow() {
    local ns=$1
    local name=$2
    # Escucha en background por 2 segundos buscando ICMP
    timeout 2 sudo ip netns exec "$ns" tcpdump -l -nn -i any icmp 2>/dev/null &
}

echo "🔍 Iniciando monitor de tráfico en cascada..."

# 1. Lanzamos escuchas en los puntos clave usando tus variables de lab.conf
check_flow "$NS_CORE_SVC"  "CORE-SVC"
check_flow "$NS_CORE_EDGE" "CORE-EDGE"
check_flow "$NS_EDGE_1"    "EDGE-1"
check_flow "$NS_INTERNET"  "INTERNET"

sleep 1 # Dar tiempo a tcpdump a engancharse

echo "🚀 Lanzando PING de prueba desde $NS_CORE_SVC (VLAN 10) -> Internet..."

# 2. Ejecutar un solo ping para ver el rastro
sudo ip netns exec "$NS_CORE_SVC" ping -c 1 -I eth1.10 203.0.113.2 > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "✅ ${GREEN}¡EL PAQUETE LLEGÓ Y VOLVIÓ!${NC}"
else
    echo -e "❌ ${RED}EL PAQUETE SE PERDIÓ EN EL CAMINO.${NC}"
    echo "💡 Revisa los logs de arriba para ver hasta qué nodo llegó el REQUEST."
fi

# El script terminará solo gracias al 'timeout' de los tcpdumps