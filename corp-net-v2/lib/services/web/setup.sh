#!/bin/bash
# lib/services/web/setup.sh

setup_web_service() {
    local ns="SVC-WEB"
    echo "🌐 Configurando Nginx en el namespace $ns..."

    # 1. Crear directorios temporales para que Nginx no choque con el host
    # Nginx necesita carpetas para logs y temporales
    ip netns exec "$ns" mkdir -p /var/log/nginx /var/lib/nginx /var/www/html

    # 2. Crear una página index básica
    echo "<h1>CorpNet V2: Servidor Web Real</h1><p>Nodo: $ns</p>" | \
        ip netns exec "$ns" tee /var/www/html/index.html > /dev/null

    # 3. Lanzar Nginx usando el archivo de configuración personalizado
    # Usamos -c para pasarle nuestra ruta y -g para que no corra como daemon
    # (Para que el proceso sea controlado o rastreable)
    ip netns exec "$ns" nginx -c "$BASE_DIR/lib/services/web/nginx.conf" -g "daemon on;"

    if [ $? -eq 0 ]; then
        echo "✅ Nginx iniciado correctamente en $ns."
    else
        echo "❌ Error al iniciar Nginx."
    fi
}