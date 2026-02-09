#!/bin/bash
# lib/services/web/setup.sh
source "$BASE_DIR/lib/services/web/ssl.sh"

setup_web_service() {
    local ns="SVC-WEB"
    local cert_src="$BASE_DIR/lib/services/web/certs"
    local web_root="/var/www/html"
    
    generate_certs
    ip netns exec "$ns" pkill -9 nginx 2>/dev/null

    # Crear directorios para ambas webs
    ip netns exec "$ns" mkdir -p $web_root/rh $web_root/monitor /etc/nginx/ssl /var/log/nginx

    # VARIABLES DINÁMICAS
    local deploy_time=$(date +'%H:%M:%S')

    # --- PROCESAR WEB RRHH ---
    sed -e "s/\${NODE_NAME}/$ns/g" "$BASE_DIR/lib/services/web/html/rh/index.html" > /tmp/rh.html
    cat /tmp/rh.html | ip netns exec "$ns" tee $web_root/rh/index.html > /dev/null

    # --- PROCESAR WEB MONITOR ---
    sed -e "s/\${NODE_NAME}/$ns/g" -e "s/\${DEPLOY_DATE}/$deploy_time/g" \
        "$BASE_DIR/lib/services/web/html/monitor/index.html" > /tmp/monitor.html
    cat /tmp/monitor.html | ip netns exec "$ns" tee $web_root/monitor/index.html > /dev/null

    # Inyectar Certificados y Configuración
    cat "$cert_src/server.crt" | ip netns exec "$ns" tee /etc/nginx/ssl/server.crt > /dev/null
    cat "$cert_src/server.key" | ip netns exec "$ns" tee /etc/nginx/ssl/server.key > /dev/null
    
    # Lanzar Nginx
    ip netns exec "$ns" nginx -c "$BASE_DIR/lib/services/web/nginx.conf" -g "daemon on;"
    
    echo "✅ Servidor Web Dual (RH/Monitor) desplegado en $ns."
}