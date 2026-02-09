#!/bin/bash
# lib/services/web/monitor.sh

check_monitor() {
    local target_ip="10.0.1.10"
    local ns="USR-RH-2" # Usamos este porque tiene permiso 443
    local cfg_file="/tmp/lynx.cfg"

    echo "📡 Conectando al Panel de Control desde $ns..."
    
    # Preparamos el entorno dentro del namespace
    ip netns exec "$ns" bash -c "echo 'FORCE_SSL_PROMPT:YES' > $cfg_file"
    
    # Ejecutamos el monitor
    ip netns exec "$ns" lynx -cfg=$cfg_file -accept_all_cookies https://$target_ip
}