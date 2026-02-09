#!/bin/bash
# lib/services/web/setup.sh
source "$BASE_DIR/lib/services/web/ssl.sh"

setup_web_service() {
    local ns="SVC-WEB"
    local cert_src="$BASE_DIR/lib/services/web/certs"
    local web_root="/var/www/html"
    local template="$BASE_DIR/lib/services/web/html/index.html"
    
    # 1. Asegurar certificados
    generate_certs

    # 2. Limpieza total de procesos previos en el NS para evitar bloqueos
    ip netns exec "$ns" pkill -9 nginx 2>/dev/null

    # 3. Preparar estructura de carpetas dentro del Namespace
    ip netns exec "$ns" mkdir -p $web_root /etc/nginx/ssl /var/log/nginx /var/lib/nginx

    # 4. PROCESAR HTML DINÁMICO (Método Seguro)
    local deploy_time=$(date +'%H:%M:%S')
    
    # Creamos el archivo final en el host reemplazando las variables
    sed -e "s/\${NODE_NAME}/$ns/g" \
        -e "s/\${DEPLOY_DATE}/$deploy_time/g" \
        "$template" > /tmp/index_final.html
    
    # Lo movemos al interior del namespace
    cat /tmp/index_final.html | ip netns exec "$ns" tee $web_root/index.html > /dev/null
    rm /tmp/index_final.html

    # 5. Inyectar Certificados SSL
    cat "$cert_src/server.crt" | ip netns exec "$ns" tee /etc/nginx/ssl/server.crt > /dev/null
    cat "$cert_src/server.key" | ip netns exec "$ns" tee /etc/nginx/ssl/server.key > /dev/null

    # 6. Lanzar Nginx
    # Importante: Usamos la ruta absoluta al config
    ip netns exec "$ns" nginx -c "$BASE_DIR/lib/services/web/nginx.conf" -g "daemon on;"
    
    if [ $? -eq 0 ]; then
        echo "✅ Dashboard Dinámico y Nginx HTTPS (443) activo en $ns."
    else
        echo "❌ Error al iniciar Nginx. Revisa la configuración."
    fi
}