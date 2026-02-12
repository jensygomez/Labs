#!/bin/bash
# lib/services/web/monitor.sh

check_monitor() {
    local target_ip="10.0.1.10"
    local ns="USR-IT-ADMIN" # <--- Ahora TI es el responsable
    local cfg_file="/tmp/lynx.cfg"

    echo "🔐 Iniciando sesión como Administrador de TI..."
    
    # Verificamos si el namespace existe antes de intentar entrar
    if ! ip netns list | grep -q "$ns"; then
        echo "❌ Error: El nodo $ns no está desplegado."
        sleep 2
        return
    fi

    ip netns exec "$ns" bash -c "echo 'FORCE_SSL_PROMPT:YES' > $cfg_file"
    ip netns exec "$ns" lynx -cfg=$cfg_file -accept_all_cookies https://$target_ip
}