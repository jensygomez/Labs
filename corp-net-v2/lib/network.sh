#!/bin/bash
# lib/network.sh - Maestro Electricista con Soporte para Bridges

VETH_COUNTER_FILE="/tmp/veth_counter"

setup_counter() {
    echo 0 > "$VETH_COUNTER_FILE"
}

ensure_cable() {
    local ns_a="$1" if_a="$2" ns_b="$3" if_b="$4"
    
    if ip netns exec "$ns_a" ip link show "$if_a" &>/dev/null && \
       ip netns exec "$ns_b" ip link show "$if_b" &>/dev/null; then
        return 0
    fi

    local counter=$(<"$VETH_COUNTER_FILE")
    echo $((counter + 1)) > "$VETH_COUNTER_FILE"
    local tmp_veth_a="v${counter}a"
    local tmp_veth_b="v${counter}b"

    ip link add "$tmp_veth_a" type veth peer name "$tmp_veth_b"
    ip link set "$tmp_veth_a" netns "$ns_a"
    ip link set "$tmp_veth_b" netns "$ns_b"
    ip netns exec "$ns_a" ip link set "$tmp_veth_a" name "$if_a" up
    ip netns exec "$ns_b" ip link set "$tmp_veth_b" name "$if_b" up
}

setup_network() {
    echo "🔗 Iniciando cableado dinámico..."
    setup_counter
    
    # 1. Crear bridges EN EL ROUTER para cada subred
    local subnets=$($YQ '.nodes[] | select(.role == "router") | .subnets[].name' "$BASE_DIR/topology/nodes.yml")
    for sn in $subnets; do
        local sn_net=$($YQ ".nodes[] | select(.role == \"router\") | .subnets[] | select(.name == \"$sn\") | .network" "$BASE_DIR/topology/nodes.yml")
        local sn_gw=$(echo "$sn_net" | sed 's/0\/24/1/')
        local br_name="br-${sn,,}"
        
        if ! ip netns exec CORE-GW ip link show "$br_name" &>/dev/null; then
            ip netns exec CORE-GW ip link add "$br_name" type bridge
            ip netns exec CORE-GW ip addr add "$sn_gw/24" dev "$br_name"
            ip netns exec CORE-GW ip link set "$br_name" up
            echo "🏢 Bridge $br_name ($sn_gw) creado en CORE-GW"
        fi
    done
    
    # 2. Conectar cada nodo a su bridge
    local nodes=$($YQ '.nodes[] | select(.role != "router") | .name' "$BASE_DIR/topology/nodes.yml")
    for node in $nodes; do
        local subnet=$($YQ ".nodes[] | select(.name == \"$node\") | .subnet" "$BASE_DIR/topology/nodes.yml")
        local ip=$($YQ ".nodes[] | select(.name == \"$node\") | .ip" "$BASE_DIR/topology/nodes.yml")
        local br_target="br-${subnet,,}"
        local if_en_router="v-${node:0:12}"
        local gw_ip=$(echo "$ip" | cut -d. -f1-3).1
        
        echo "🔗 Conectando $node → $br_target..."
        
        ensure_cable "$node" "eth0" "CORE-GW" "$if_en_router"
        
        # Conectar al bridge (solo si no es ya miembro)
        if ! ip netns exec CORE-GW ip link show "$if_en_router" | grep -q "master $br_target"; then
            ip netns exec CORE-GW ip link set "$if_en_router" master "$br_target"
            ip netns exec CORE-GW ip link set "$if_en_router" up
        fi
        
        # Configurar IP del nodo (con check de error para evitar el "File Exists")
        if ! ip netns exec "$node" ip addr show eth0 | grep -q "$ip"; then
            ip netns exec "$node" ip addr add "$ip/24" dev eth0
        fi

        # Configurar Ruta (con check de error)
        if ! ip netns exec "$node" ip route show | grep -q "default via $gw_ip"; then
            ip netns exec "$node" ip route add default via "$gw_ip"
        fi
    done
    
    ip netns exec CORE-GW sysctl -w net.ipv4.ip_forward=1 > /dev/null
    echo "✅ Red configurada con Bridges correctamente"
}