run_phase() {
    
    # network-engine/phases/100-connectivity-test.sh
    set -Eeuo pipefail

    echo "===================================================="
    echo "[FASE 100] CONNECTIVITY MATRIX (DINÁMICO)"
    echo "===================================================="

    # 1. Obtener todos los namespaces
    namespaces=($(ip netns list | awk '{print $1}'))

    declare -A ip_map

    # 2. Obtener IPs de cada namespace
    for ns in "${namespaces[@]}"; do
        # Obtener todas las IPs del namespace
        ips=$(ip netns exec "$ns" ip -4 addr show | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
        
        for ip in $ips; do
            # Guardar con clave única: NAMESPACE o NAMESPACE_INTERFAZ
            iface=$(ip netns exec "$ns" ip -4 addr show | grep "$ip" | awk '{print $NF}')
            key="${ns}_${iface}"
            ip_map["$key"]="$ip"
            
            # También guardar solo por namespace (última IP encontrada)
            ip_map["$ns"]="$ip"
        done
    done

    # 3. Función de test
    test_ping() {
        local src_ns="$1"
        local dst_ip="$2"
        local dst_name="$3"
        
        printf "%-15s → %-25s : " "$src_ns" "$dst_name"
        
        if timeout 2 ip netns exec "$src_ns" ping -c 1 -W 1 "$dst_ip" &>/dev/null; then
            echo "✅"
        else
            echo "❌"
        fi
    }

    # 4. Ejecutar tests
    echo "🔍 Probando conectividad entre ${#namespaces[@]} namespaces..."
    echo ""

    for src_ns in "${namespaces[@]}"; do
        echo "--- Desde $src_ns ---"
        
        for key in "${!ip_map[@]}"; do
            dst_ip="${ip_map[$key]}"
            
            # No probarse a sí mismo (misma IP)
            if [[ "$key" =~ ^${src_ns}_ ]] || [[ "$key" == "$src_ns" ]]; then
                continue
            fi
            
            # Extraer namespace destino del key
            dst_ns="${key%%_*}"
            if [[ "$dst_ns" == "$key" ]]; then
                # Key es solo namespace (sin interfaz)
                dst_ns="$key"
            fi
            
            test_ping "$src_ns" "$dst_ip" "$key"
        done
        echo ""
    done

    echo "===================================================="
    echo "✅ Matriz de conectividad completada"
    echo "===================================================="

}