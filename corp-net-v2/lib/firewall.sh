#!/bin/bash
# lib/firewall.sh - Microsegmentación Dinámica

apply_firewall() {
    echo "🛡️  Configurando Microsegmentación Zero-Trust..."

    local nodes=$($YQ '.nodes[].name' "$BASE_DIR/topology/nodes.yml")

    for node in $nodes; do
        echo "   🔒 Nodo: $node"

        # 1. Reset y Políticas base (Cerrar todo)
        ip netns exec "$node" iptables -F
        ip netns exec "$node" iptables -P INPUT DROP
        ip netns exec "$node" iptables -P FORWARD DROP
        ip netns exec "$node" iptables -P OUTPUT ACCEPT
        
        # 2. Permitir lo esencial (Loopback y conexiones establecidas)
        ip netns exec "$node" iptables -A INPUT -i lo -j ACCEPT
        ip netns exec "$node" iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        ip netns exec "$node" iptables -A INPUT -p icmp -j ACCEPT 

        # 3. Leer reglas de acceso desde el YAML
        # Obtenemos cuántas reglas de 'allow_inbound' tiene este nodo
        local num_rules=$($YQ ".nodes[] | select(.name == \"$node\") | .allow_inbound | length" "$BASE_DIR/topology/nodes.yml")

        # Si yq devuelve vacío o null, num_rules será 0
        [[ "$num_rules" == "null" ]] && num_rules=0

        for (( i=0; i<$num_rules; i++ )); do
            local remote_name=$($YQ ".nodes[] | select(.name == \"$node\") | .allow_inbound[$i].from" "$BASE_DIR/topology/nodes.yml")
            local port=$($YQ ".nodes[] | select(.name == \"$node\") | .allow_inbound[$i].port" "$BASE_DIR/topology/nodes.yml")
            
            # Buscamos la IP del nodo origen
            local remote_ip=$($YQ ".nodes[] | select(.name == \"$remote_name\") | .ip" "$BASE_DIR/topology/nodes.yml")

            if [[ "$remote_ip" != "null" && "$port" != "null" ]]; then
                ip netns exec "$node" iptables -A INPUT -s "$remote_ip" -p tcp --dport "$port" -j ACCEPT
                echo "      ✅ Regla inyectada: Desde $remote_name ($remote_ip) al puerto $port"
            fi
        done
    done

    # 4. Router CORE-GW: Permitimos el paso (Forwarding)
    ip netns exec CORE-GW iptables -P FORWARD ACCEPT
}