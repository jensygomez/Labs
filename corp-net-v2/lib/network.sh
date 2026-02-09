#!/bin/bash
# lib/network.sh - El "Maestro electricista" de la red

YQ="./.bin/yq"

setup_network() {
    echo "🔗 Iniciando cableado dinámico..."

    # USAMOS "$BASE_DIR/topology/nodes.yml" para que yq siempre lo encuentre
    local nodes=$($YQ '.nodes[] | select(.role != "router") | .name' "$BASE_DIR/topology/nodes.yml")

    for node in $nodes; do
        # Extraer datos usando la ruta absoluta
        local ip=$($YQ ".nodes[] | select(.name == \"$node\") | .ip" "$BASE_DIR/topology/nodes.yml")
        local subnet=$($YQ ".nodes[] | select(.name == \"$node\") | .subnet" "$BASE_DIR/topology/nodes.yml")
        
        # El Gateway (usamos de nuevo la ruta absoluta)
        local gw_ip=$($YQ ".nodes[] | select(.role == \"router\") | .subnets[] | select(.name == \"$subnet\") | .network" "$BASE_DIR/topology/nodes.yml" | sed 's/0\/24/1/')

        echo "🌐 Conectando $node ($ip) a la subred $subnet..."

        # Nombres de las interfaces del cable
        local veth_node="eth0"
        local veth_core="v-${node}" # Nombre único en el router, ej: v-USR-RH-1

        # 2. Crear el cable Veth
        ip link add $veth_node type veth peer name $veth_core

        # 3. Mover un extremo al Nodo y el otro al Router
        ip link set $veth_node netns $node
        ip link set $veth_core netns CORE-GW

        # 4. Configurar IP en el Nodo y levantarlo
        ip netns exec $node ip addr add $ip/24 dev $veth_node
        ip netns exec $node ip link set $veth_node up
        
        # 5. Configurar IP en el lado del Router (Gateway) y levantarlo
        # Solo lo hacemos si la IP no existe ya en el router (idempotencia)
        if ! ip netns exec CORE-GW ip addr show | grep -q "$gw_ip"; then
            ip netns exec CORE-GW ip addr add $gw_ip/24 dev $veth_core
        fi
        ip netns exec CORE-GW ip link set $veth_core up

        # 6. Configurar la Ruta por Defecto en el Nodo
        ip netns exec $node ip route add default via $gw_ip
        
        echo "   ✅ Cable estirado y configurado."
    done

    # 7. Habilitar Forwarding en el CORE-GW (Vital para que sea Router)
    ip netns exec CORE-GW sysctl -w net.ipv4.ip_forward=1 > /dev/null
}