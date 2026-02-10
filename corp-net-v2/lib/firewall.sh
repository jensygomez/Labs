#!/bin/bash
# lib/firewall.sh - Microsegmentación Dinámica de Siguiente Generación

[[ -z "$YQ" ]] && YQ="$BASE_DIR/.bin/yq"

apply_firewall() {
    echo "🛡️  Aplicando Políticas Zero-Trust Evolucionadas..."

    local yaml_file="$BASE_DIR/topology/nodes.yml"
    local nodes=$($YQ '.nodes[].name' "$yaml_file")

    for node in $nodes; do
        local role=$($YQ ".nodes[] | select(.name == \"$node\") | .role" "$yaml_file")
        echo "   🔒 Asegurando Nodo: $node ($role)"

        # 1. Limpieza y Política por Defecto
        ip netns exec "$node" iptables -F
        ip netns exec "$node" iptables -P INPUT DROP
        ip netns exec "$node" iptables -P OUTPUT ACCEPT
        
        # El Router debe permitir el paso (FORWARD), los demás no.
        if [[ "$role" == "router" ]]; then
            ip netns exec "$node" iptables -P FORWARD ACCEPT
            echo "      ⚡ Router detectado: Forwarding habilitado."
        else
            ip netns exec "$node" iptables -P FORWARD DROP
        fi
        
        # 2. Servicios Esenciales
        ip netns exec "$node" iptables -A INPUT -i lo -j ACCEPT
        ip netns exec "$node" iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        ip netns exec "$node" iptables -A INPUT -p icmp -j ACCEPT 

        # 3. Inyectar Reglas Dinámicas
        local num_rules=$($YQ ".nodes[] | select(.name == \"$node\") | .allow_inbound | length" "$yaml_file")
        [[ "$num_rules" == "null" || -z "$num_rules" ]] && num_rules=0

        for (( i=0; i<$num_rules; i++ )); do
            local raw_from=$($YQ ".nodes[] | select(.name == \"$node\") | .allow_inbound[$i].from" "$yaml_file")
            local raw_port=$($YQ ".nodes[] | select(.name == \"$node\") | .allow_inbound[$i].port" "$yaml_file")
            
            # --- LÓGICA DE ORIGEN (from) ---
            local final_src=""
            if [[ "$raw_from" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
                # Es una IP o CIDR (ej: 10.0.3.0/24)
                final_src="$raw_from"
            else
                # Es un nombre de nodo (ej: USR-RH-1), buscamos su IP
                final_src=$($YQ ".nodes[] | select(.name == \"$raw_from\") | .ip" "$yaml_file")
            fi

            # --- LÓGICA DE PUERTO (port) ---
            local port_cmd=""
            if [[ "$raw_port" == "any" ]]; then
                port_cmd="" # No añadimos restricción de puerto
            else
                port_cmd="-p tcp --dport $raw_port"
            fi

            # Aplicar la regla si el origen es válido
            if [[ "$final_src" != "null" && -n "$final_src" ]]; then
                ip netns exec "$node" iptables -A INPUT -s "$final_src" $port_cmd -j ACCEPT
                echo "      ✅ Permitir: $final_src -> Puerto: ${raw_port^^}"
            fi
        done
    done
    echo "✅ Políticas de Microsegmentación aplicadas globalmente."
}