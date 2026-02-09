#!/bin/bash
# lib/services/web/setup.sh

setup_web_service() {
    local ns="SVC-WEB"
    local source_html="$BASE_DIR/lib/services/web/html"
    
    echo "🌐 Sincronizando contenido web en $ns..."

    # Crear la ruta dentro del namespace
    ip netns exec "$ns" mkdir -p /var/www/html

    # Copiar todos los archivos de nuestra carpeta html/ al namespace
    # Esto permite tener imágenes, CSS, o múltiples páginas .html
    cp -r $source_html/* /tmp/html_temp/ 2>/dev/null # Ejemplo de paso intermedio si fuera necesario
    
    # Lo más directo para este lab:
    cat "$source_html/index.html" | ip netns exec "$ns" tee /var/www/html/index.html > /dev/null
    
    # Lanzar Nginx
    ip netns exec "$ns" nginx -c "$BASE_DIR/lib/services/web/nginx.conf" -g "daemon on;"
}