#!/bin/bash
# lib/firewall.sh - Microsegmentación Dinámica
[[ -z "$YQ" ]] && YQ="$BASE_DIR/.bin/yq"
apply_firewall() {
    echo "🛡️  Configurando Microsegmentación Zero-Trust..."

    # Validación de ruta
    local yaml_file="$BASE_DIR/topology/nodes.yml"
    if [ ! -f "$yaml_file" ]; then
        echo "❌ Error: No se encuentra el archivo $yaml_file"
        return 1
    fi

    local nodes=$($YQ '.nodes[].name' "$yaml_file")

    for node in $nodes; do
        echo "   🔒 Nodo: $node"

        # 1. Limpieza y Política DROP (Cerrar la puerta)
        ip netns exec "$node" iptables -F
        ip netns exec "$node" iptables -P INPUT DROP
        ip netns exec "$node" iptables -P FORWARD DROP
        ip netns exec "$node" iptables -P OUTPUT ACCEPT
        
        # 2. Permitir Loopback y Estado
        ip netns exec "$node" iptables -A INPUT -i lo -j ACCEPT
        ip netns exec "$node" iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        ip netns exec "$node" iptables -A INPUT -p icmp -j ACCEPT 

        # 3. Inyectar reglas desde el YAML
        local num_rules=$($YQ ".nodes[] | select(.name == \"$node\") | .allow_inbound | length" "$yaml_file")
        
        # Si num_rules es null o vacío, lo tratamos como 0
        if [[ "$num_rules" == "null" || -z "$num_rules" ]]; then num_rules=0; fi

        for (( i=0; i<$num_rules; i++ )); do
            local remote_name=$($YQ ".nodes[] | select(.name == \"$node\") | .allow_inbound[$i].from" "$yaml_file")
            local port=$($YQ ".nodes[] | select(.name == \"$node\") | .allow_inbound[$i].port" "$yaml_file")
            
            # Buscar la IP del origen
            local remote_ip=$($YQ ".nodes[] | select(.name == \"$remote_name\") | .ip" "$yaml_file")

            if [[ "$remote_ip" != "null" && "$port" != "null" ]]; then
                ip netns exec "$node" iptables -A INPUT -s "$remote_ip" -p tcp --dport "$port" -j ACCEPT
                echo "      ✅ Regla: Permitir $remote_name ($remote_ip) -> Puerto $port"
            fi
        done
    done

    # 4. Router CORE-GW: Permitir paso de paquetes entre redes
    ip netns exec CORE-GW iptables -P FORWARD ACCEPT
}