#!/bin/bash
# corp-net-v2/lib/network.sh
# Motor de Red Dinámico para Arquitecturas Jerárquicas

[[ -z "$YQ" ]] && YQ="$BASE_DIR/.bin/yq"
VETH_COUNTER_FILE="/tmp/veth_counter"

setup_counter() { echo 0 > "$VETH_COUNTER_FILE"; }

ensure_cable() {
    local ns_a="$1" if_a="$2" ns_b="$3" if_b="$4"
    if ip netns exec "$ns_a" ip link show "$if_a" &>/dev/null && \
       ip netns exec "$ns_b" ip link show "$if_b" &>/dev/null; then
        return 0
    fi
    local counter=$(<"$VETH_COUNTER_FILE")
    echo $((counter + 1)) > "$VETH_COUNTER_FILE"
    local v_a="v${counter}a" local v_b="v${counter}b"
    ip link add "$v_a" type veth peer name "$v_b"
    ip link set "$v_a" netns "$ns_a"
    ip link set "$v_b" netns "$ns_b"
    ip netns exec "$ns_a" ip link set "$v_a" name "$if_a" up
    ip netns exec "$ns_b" ip link set "$v_b" name "$if_b" up
}

setup_network() {
    echo "🌐 [MOTOR] Escaneando topología jerárquica..."
    setup_counter

    # 1. Fase de Routers y Bridges
    local routers=$($YQ '.nodes[] | select(.role == "router") | .name' "$BASE_DIR/topology/nodes.yml")
    
    for rtr in $routers; do
        echo "🏗️  Configurando Gateway: $rtr"
        # Habilitar forwarding de inmediato
        ip netns exec "$rtr" sysctl -w net.ipv4.ip_forward=1 > /dev/null

        # Obtener todas las subredes asignadas a este router
        local sn_names=$($YQ ".nodes[] | select(.name == \"$rtr\") | .subnets[].name" "$BASE_DIR/topology/nodes.yml")
        
        for sn in $sn_names; do
            local sn_net=$($YQ ".nodes[] | select(.name == \"$rtr\") | .subnets[] | select(.name == \"$sn\") | .network" "$BASE_DIR/topology/nodes.yml")
            # Extraer IP del Gateway (la .1 de la red)
            local gw_ip=$(echo "$sn_net" | sed 's/0\/24/1/')
            local br_name="${sn,,}" # Usamos el nombre del bridge directamente del YAML

            if ! ip netns exec "$rtr" ip link show "$br_name" &>/dev/null; then
                ip netns exec "$rtr" ip link add "$br_name" type bridge
                ip netns exec "$rtr" ip addr add "$gw_ip/24" dev "$br_name"
                ip netns exec "$rtr" ip link set "$br_name" up
                echo "   └─ 🌐 Switch Virtual [$br_name] activo (GW: $gw_ip)"
            fi
        done
    done

    # 2. Fase de Conexión de Nodos (Endpoints)
    local endpoints=$($YQ '.nodes[] | select(.role != "router") | .name' "$BASE_DIR/topology/nodes.yml")
    
    for node in $endpoints; do
        local br_target=$($YQ ".nodes[] | select(.name == \"$node\") | .subnet" "$BASE_DIR/topology/nodes.yml")
        local node_ip=$($YQ ".nodes[] | select(.name == \"$node\") | .ip" "$BASE_DIR/topology/nodes.yml")
        
        # Validación: Si no tiene bridge o IP, saltamos (como el caso de un nodo futuro vacío)
        if [[ "$br_target" == "null" || "$node_ip" == "null" ]]; then 
            echo "💤 Nodo $node detectado (En espera de configuración)"
            continue 
        fi

        # Buscar qué router es el dueño del bridge al que se quiere conectar este nodo
        local rtr_owner=$($YQ ".nodes[] | select(.role == \"router\" and .subnets[].name == \"$br_target\") | .name" "$BASE_DIR/topology/nodes.yml")
        
        if [[ -z "$rtr_owner" ]]; then
            echo "⚠️  Error: El bridge $br_target para $node no tiene un Router asignado."
            continue
        fi

        local if_rtr="v-${node:0:10}" # Nombre corto para el router
        local gw_ip=$(echo "$node_ip" | cut -d. -f1-3).1

        echo "🔗 Cableando: $node [$node_ip] <---> $rtr_owner [$br_target]"
        
        ensure_cable "$node" "eth0" "$rtr_owner" "$if_rtr"
        
        # Enchufar al bridge del router
        ip netns exec "$rtr_owner" ip link set "$if_rtr" master "$br_target" 2>/dev/null
        ip netns exec "$rtr_owner" ip link set "$if_rtr" up
        
        # Configuración IP y Ruta del nodo
        ip netns exec "$node" ip addr add "$node_ip/24" dev eth0 2>/dev/null
        ip netns exec "$node" ip route add default via "$gw_ip" 2>/dev/null
    done
    echo "✅ Infraestructura de red desplegada y ruteada."
}