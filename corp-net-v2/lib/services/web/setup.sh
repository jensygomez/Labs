#!/bin/bash
# lib/services/web/setup.sh
source "$BASE_DIR/lib/services/web/ssl.sh"

setup_web_service() {
    local ns="SVC-WEB"
    local cert_src="$BASE_DIR/lib/services/web/certs"
    
    # 1. Generar certificados en el host
    generate_certs

    # 2. Preparar carpetas en el Namespace
    ip netns exec "$ns" mkdir -p /var/www/html /etc/nginx/ssl /var/lib/nginx /var/log/nginx

    # 3. Inyectar Certificados y HTML
    cat "$BASE_DIR/lib/services/web/html/index.html" | ip netns exec "$ns" tee /var/www/html/index.html > /dev/null
    cat "$cert_src/server.crt" | ip netns exec "$ns" tee /etc/nginx/ssl/server.crt > /dev/null
    cat "$cert_src/server.key" | ip netns exec "$ns" tee /etc/nginx/ssl/server.key > /dev/null

    # 4. Lanzar Nginx
    ip netns exec "$ns" nginx -c "$BASE_DIR/lib/services/web/nginx.conf" -g "daemon on;"
    echo "✅ Nginx HTTPS (443) desplegado en $ns."
}