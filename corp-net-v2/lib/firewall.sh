#!/bin/bash
# corp-net-v2/lib/firewall.sh
# Orquestador de seguridad distribuida

apply_firewall() {
    echo "🛡️  Iniciando Microsegmentación de red..."

    local nodes=$($YQ '.nodes[].name' "$BASE_DIR/topology/nodes.yml")

    for node in $nodes; do
        echo "   🔒 Aplicando políticas locales en: $node"
        
        # 1. Limpiar reglas actuales del nodo
        ip netns exec "$node" iptables -F
        
        # 2. Configurar política por defecto
        ip netns exec "$node" iptables -P INPUT DROP
        ip netns exec "$node" iptables -P FORWARD DROP
        ip netns exec "$node" iptables -P OUTPUT ACCEPT

        # 3. Reglas básicas comunes (Loopback y Estado)
        ip netns exec "$node" iptables -A INPUT -i lo -j ACCEPT
        ip netns exec "$node" iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        
        # 4. Permitir PING (Opcional, para tus pruebas)
        ip netns exec "$node" iptables -A INPUT -p icmp -j ACCEPT

        # 5. DINAMISMO: Abrir puertos del YAML para este nodo específico
        local ports=$($YQ ".nodes[] | select(.name == \"$node\") | .services[]" "$BASE_DIR/topology/nodes.yml" 2>/dev/null)
        
        for port in $ports; do
            if [ "$port" != "null" ]; then
                ip netns exec "$node" iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
                echo "      ✅ Puerto $port abierto en $node"
            fi
        done
    done
}
configure_router_security() {
    echo "🌐 Configurando políticas de tránsito en CORE-GW..."
    # Por ahora, permitimos que el tráfico fluya (FORWARD ACCEPT) 
    # pero solo si ya está establecida la conexión o es tráfico nuevo permitido
    ip netns exec CORE-GW iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    # Aquí es donde podrías decir: "Solo permite de USERS a MGMT puerto 80"
}