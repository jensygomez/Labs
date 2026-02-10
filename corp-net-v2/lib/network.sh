#!/bin/bash
# corp-net-v2/lib/network.sh
#Maestro Electricista con Soporte para Bridges

[[ -z "$YQ" ]] && YQ="$BASE_DIR/.bin/yq"
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

#!/bin/bash
# Maestro de Red Universal - Sin Hardcoding

setup_network() {
    echo "🌐 Detectando infraestructura de red..."
    setup_counter
    
    # 1. Identificar al Router (o Routers)
    local routers=$($YQ '.nodes[] | select(.role == "router") | .name' "$BASE_DIR/topology/nodes.yml")
    
    for rtr in $routers; do
        echo "🏗️  Configurando Router: $rtr"
        
        # 2. Crear Bridges dinámicos para ESTE router específico
        local subnets=$($YQ ".nodes[] | select(.name == \"$rtr\") | .subnets[].name" "$BASE_DIR/topology/nodes.yml")
        
        for sn in $subnets; do
            local sn_net=$($YQ ".nodes[] | select(.name == \"$rtr\") | .subnets[] | select(.name == \"$sn\") | .network" "$BASE_DIR/topology/nodes.yml")
            local sn_gw=$(echo "$sn_net" | sed 's/0\/24/1/')
            local br_name="br-${sn,,}"
            
            if ! ip netns exec "$rtr" ip link show "$br_name" &>/dev/null; then
                ip netns exec "$rtr" ip link add "$br_name" type bridge
                ip netns exec "$rtr" ip addr add "$sn_gw/24" dev "$br_name"
                ip netns exec "$rtr" ip link set "$br_name" up
                echo "   └─ Switch [$br_name] -> IP Gateway: $sn_gw"
            fi
        done
        
        # Habilitar forwarding en este router
        ip netns exec "$rtr" sysctl -w net.ipv4.ip_forward=1 > /dev/null
    done

    # 3. Conectar Nodos a sus respectivos Routers/Bridges
    local clients=$($YQ '.nodes[] | select(.role != "router") | .name' "$BASE_DIR/topology/nodes.yml")
    
    for node in $clients; do
        local subnet_name=$($YQ ".nodes[] | select(.name == \"$node\") | .subnet" "$BASE_DIR/topology/nodes.yml")
        local node_ip=$($YQ ".nodes[] | select(.name == \"$node\") | .ip" "$BASE_DIR/topology/nodes.yml")
        
        # IMPORTANTE: Buscamos qué router es el dueño de esa subnet
        local rtr_owner=$($YQ ".nodes[] | select(.role == \"router\" and .subnets[].name == \"$subnet_name\") | .name" "$BASE_DIR/topology/nodes.yml")
        
        local br_target="br-${subnet_name,,}"
        local if_rtr="v-${node:0:12}"
        local gw_ip=$(echo "$node_ip" | cut -d. -f1-3).1

        echo "🔗 Conectando $node ---> $rtr_owner [$br_target]"
        
        ensure_cable "$node" "eth0" "$rtr_owner" "$if_rtr"
        
        # Atar al bridge del router correspondiente
        ip netns exec "$rtr_owner" ip link set "$if_rtr" master "$br_target" 2>/dev/null
        ip netns exec "$rtr_owner" ip link set "$if_rtr" up
        
        # Configurar IP y Ruta Default
        ip netns exec "$node" ip addr add "$node_ip/24" dev eth0 2>/dev/null
        ip netns exec "$node" ip route add default via "$gw_ip" 2>/dev/null
    done
}