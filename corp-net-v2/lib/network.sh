#!/bin/bash
# lib/network.sh - El "Maestro electricista" con lógica de abstracción

VETH_COUNTER_FILE="/tmp/veth_counter"

# Inicializar contador si no existe
setup_counter() {
    echo 0 > "$VETH_COUNTER_FILE"
}

# La función core que mencionaste, adaptada
ensure_cable() {
    local ns_a="$1" if_a="$2" ns_b="$3" if_b="$4"

    # Idempotencia: Si ya existe el cable en ambos lados, no hacer nada
    if ip netns exec "$ns_a" ip link show "$if_a" &>/dev/null && \
       ip netns exec "$ns_b" ip link show "$if_b" &>/dev/null; then
        return 0
    fi

    local counter=$(<"$VETH_COUNTER_FILE")
    echo $((counter + 1)) > "$VETH_COUNTER_FILE"

    local tmp_veth_a="v${counter}a"
    local tmp_veth_b="v${counter}b"

    # Crear par veth en el host temporalmente
    ip link add "$tmp_veth_a" type veth peer name "$tmp_veth_b"

    # Mover a los namespaces
    ip link set "$tmp_veth_a" netns "$ns_a"
    ip link set "$tmp_veth_b" netns "$ns_b"

    # Renombrar a nombres estándar (ej: eth0 o v-ethX) y levantar
    ip netns exec "$ns_a" ip link set "$tmp_veth_a" name "$if_a" up
    ip netns exec "$ns_b" ip link set "$tmp_veth_b" name "$if_b" up
}

setup_network() {
    echo "🔗 Iniciando cableado dinámico (Modo Abstracción)..."
    setup_counter

    # 1. Obtener nodos que necesitan conexión al router
    local nodes=$($YQ '.nodes[] | select(.role != "router") | .name' "$BASE_DIR/topology/nodes.yml")

    for node in $nodes; do
        local ip=$($YQ ".nodes[] | select(.name == \"$node\") | .ip" "$BASE_DIR/topology/nodes.yml")
        local subnet=$($YQ ".nodes[] | select(.name == \"$node\") | .subnet" "$BASE_DIR/topology/nodes.yml")
        
        # Obtener la IP del GW para esa subred
        local gw_ip=$($YQ ".nodes[] | select(.role == \"router\") | .subnets[] | select(.name == \"$subnet\") | .network" "$BASE_DIR/topology/nodes.yml" | sed 's/0\/24/1/')

        # Definimos nombres estandarizados
        local if_en_nodo="eth0"
        local if_en_router="v-${node:0:12}" # Recortamos a 12 char para evitar el límite de 15 de Linux

        echo "🌐 Conectando $node ↔ CORE-GW..."
        
        # USAMOS TU LÓGICA DINÁMICA
        ensure_cable "$node" "$if_en_nodo" "CORE-GW" "$if_en_router"

        # Configuración de IPs y Rutas
        ip netns exec "$node" ip addr add "$ip/24" dev "$if_en_nodo" 2>/dev/null
        
        # Solo poner la IP en el router si esa subred no tiene interfaz aún
        if ! ip netns exec CORE-GW ip addr show | grep -q "$gw_ip"; then
            ip netns exec CORE-GW ip addr add "$gw_ip/24" dev "$if_en_router"
        fi

        # Ruta por defecto
        ip netns exec "$node" ip route add default via "$gw_ip" 2>/dev/null
    done

    # Habilitar Forwarding
    ip netns exec CORE-GW sysctl -w net.ipv4.ip_forward=1 > /dev/null
}