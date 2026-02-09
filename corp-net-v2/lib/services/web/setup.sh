#!/bin/bash
# lib/services/web/setup.sh
source "$BASE_DIR/lib/services/web/ssl.sh"

setup_web_service() {
    local ns="SVC-WEB"
    local cert_src="$BASE_DIR/lib/services/web/certs"
    local web_root="/var/www/html"
    
    # 1. Generar certificados en el host
    generate_certs

    # 2. Preparar carpetas en el Namespace
    ip netns exec "$ns" mkdir -p $web_root /etc/nginx/ssl /var/lib/nginx /var/log/nginx

    # 3. PROCESAR HTML DINÁMICO
    # Leemos la plantilla y reemplazamos las variables antes de enviarla al namespace
    local template="$BASE_DIR/lib/services/web/html/index.html"
    local deploy_time=$(date +'%d/%m/%Y %H:%M:%S')
    
    # Usamos sed para inyectar los datos reales en las "marcas" del HTML
    cat "$template" | \
        sed "s/\${NODE_NAME}/$ns/g" | \
        sed "s/\${DEPLOY_DATE}/$deploy_time/g" | \
        ip netns exec "$ns" tee $web_root/index.html > /dev/null

    # 4. Inyectar Certificados
    cat "$cert_src/server.crt" | ip netns exec "$ns" tee /etc/nginx/ssl/server.crt > /dev/null
    cat "$cert_src/server.key" | ip netns exec "$ns" tee /etc/nginx/ssl/server.key > /dev/null

    # 5. Lanzar Nginx (Limpiando procesos previos si existen)
    ip netns exec "$ns" pkill nginx 2>/dev/null
    ip netns exec "$ns" nginx -c "$BASE_DIR/lib/services/web/nginx.conf" -g "daemon on;"
    
    echo "✅ Dashboard dinámico y Nginx HTTPS desplegado en $ns."
}