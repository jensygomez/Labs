#!/bin/bash
# corp-net-v2/lib/services/web/setup.sh
# Sistema Multi-Sitio con Virtual Hosts Dinámicos

source "$BASE_DIR/lib/services/web/ssl.sh"

# ==========================================
# FUNCIÓN: Preparar mime.types
# ==========================================
prepare_mime_types() {
    local mime_file="$BASE_DIR/lib/services/web/mime.types"
    
    if [ ! -f "$mime_file" ]; then
        echo "📝 Preparando mime.types..."
        
        # Intentar copiar del sistema
        if [ -f /etc/nginx/mime.types ]; then
            cp /etc/nginx/mime.types "$mime_file"
        else
            # Crear uno básico si no existe
            cat > "$mime_file" <<'EOF'
types {
    text/html                             html htm shtml;
    text/css                              css;
    text/xml                              xml;
    image/gif                             gif;
    image/jpeg                            jpeg jpg;
    application/javascript                js;
    application/json                      json;
    image/png                             png;
    image/svg+xml                         svg svgz;
    image/x-icon                          ico;
    text/plain                            txt;
    application/pdf                       pdf;
    font/woff                             woff;
    font/woff2                            woff2;
}
EOF
        fi
    fi
}

# ==========================================
# FUNCIÓN: Generar configuración Nginx por sitio
# ==========================================
generate_nginx_site_config() {
    local ns=$1
    local site_name=$2
    local server_name=$3
    local port=$4
    local root=$5
    local use_ssl=$6
    
    local config_file="/etc/nginx/conf.d/${site_name}.conf"
    
    if [ "$use_ssl" = "true" ]; then
        cat <<EOF | ip netns exec "$ns" tee "$config_file" > /dev/null
# ==========================================
# Virtual Host: $site_name (HTTPS)
# ==========================================
server {
    listen $port ssl http2;
    server_name $server_name;
    
    # Certificados SSL
    ssl_certificate     /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Logs específicos del sitio
    access_log /var/log/nginx/${site_name}_access.log;
    error_log  /var/log/nginx/${site_name}_error.log;
    
    # Raíz del sitio
    location / {
        root $root;
        index index.html index.htm;
    }
    
    # Headers de seguridad
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF
    else
        cat <<EOF | ip netns exec "$ns" tee "$config_file" > /dev/null
# ==========================================
# Virtual Host: $site_name (HTTP)
# ==========================================
server {
    listen $port;
    server_name $server_name;
    
    # Logs específicos del sitio
    access_log /var/log/nginx/${site_name}_access.log;
    error_log  /var/log/nginx/${site_name}_error.log;
    
    # Raíz del sitio
    location / {
        root $root;
        index index.html index.htm;
    }
}
EOF
    fi
}

# ==========================================
# FUNCIÓN: Desplegar HTML de un sitio
# ==========================================
deploy_site_html() {
    local ns=$1
    local site_name=$2
    local root=$3
    local template=$4
    local server_name=$5
    
    # Crear directorio del sitio
    ip netns exec "$ns" mkdir -p "$root"
    
    # Variables dinámicas para templates
    local deploy_time=$(date +'%Y-%m-%d %H:%M:%S')
    local template_path="$BASE_DIR/lib/services/web/html/$template"
    
    # Verificar si el template existe
    if [ ! -f "$template_path" ]; then
        echo "   ⚠️  Template no encontrado: $template"
        echo "   📝 Creando página por defecto..."
        
        # Usar template por defecto
        template_path="$BASE_DIR/lib/services/web/templates/default.html"
        
        # Si tampoco existe el default, crearlo
        if [ ! -f "$template_path" ]; then
            mkdir -p "$BASE_DIR/lib/services/web/templates"
            cat > "$template_path" <<'DEFAULTHTML'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${SITE_NAME} - CorpNet v2</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        .container {
            background: rgba(255,255,255,0.1);
            backdrop-filter: blur(10px);
            padding: 3rem;
            border-radius: 20px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
            text-align: center;
            max-width: 600px;
        }
        h1 { font-size: 2.5rem; margin-bottom: 1rem; }
        .badge { 
            display: inline-block;
            background: rgba(255,255,255,0.2);
            padding: 0.5rem 1rem;
            border-radius: 50px;
            margin: 0.5rem;
            font-size: 0.9rem;
        }
        .info { margin-top: 2rem; font-size: 0.9rem; opacity: 0.8; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 ${SITE_NAME}</h1>
        <p style="font-size: 1.2rem; margin: 1rem 0;">Sistema Activo</p>
        <div>
            <span class="badge">📡 ${SERVER_NAME}</span>
            <span class="badge">🖥️ ${NODE_NAME}</span>
        </div>
        <div class="info">
            <p>⏱️ Desplegado: ${DEPLOY_DATE}</p>
            <p>🏢 CorpNet Enterprise Lab v2.0</p>
        </div>
    </div>
</body>
</html>
DEFAULTHTML
        fi
    fi
    
    # Procesar template con variables
    sed -e "s/\${NODE_NAME}/$ns/g" \
        -e "s/\${SITE_NAME}/$site_name/g" \
        -e "s/\${SERVER_NAME}/$server_name/g" \
        -e "s/\${DEPLOY_DATE}/$deploy_time/g" \
        "$template_path" > /tmp/${site_name}.html
    
    # Copiar al namespace
    cat /tmp/${site_name}.html | ip netns exec "$ns" tee "$root/index.html" > /dev/null
    rm -f /tmp/${site_name}.html
}

# ==========================================
# FUNCIÓN PRINCIPAL: Setup Multi-Sitio
# ==========================================
setup_web_service() {
    local ns="SVC-WEB"
    local sites_yaml="$BASE_DIR/topology/websites.yml"
    local cert_src="$BASE_DIR/lib/services/web/certs"
    
    echo "🌐 [MOTOR] Desplegando servidor web multi-sitio..."
    
    # 1. Preparar dependencias
    prepare_mime_types
    generate_certs
    
    # 2. Limpiar procesos nginx anteriores
    ip netns exec "$ns" pkill -9 nginx 2>/dev/null
    
    # 3. Crear estructura de directorios
    ip netns exec "$ns" mkdir -p /etc/nginx/conf.d /etc/nginx/ssl /var/log/nginx
    
    # 4. Limpiar configuraciones anteriores
    ip netns exec "$ns" rm -f /etc/nginx/conf.d/*.conf
    
    # 5. Copiar certificados SSL
    cat "$cert_src/server.crt" | ip netns exec "$ns" tee /etc/nginx/ssl/server.crt > /dev/null
    cat "$cert_src/server.key" | ip netns exec "$ns" tee /etc/nginx/ssl/server.key > /dev/null
    
    # 6. Obtener número de sitios
    local site_count=$($YQ eval '.sites | length' "$sites_yaml")
    
    # 7. Iterar sobre cada sitio
    for ((i=0; i<$site_count; i++)); do
        local site_name=$($YQ eval ".sites[$i].name" "$sites_yaml")
        local server_name=$($YQ eval ".sites[$i].server_name" "$sites_yaml")
        local port=$($YQ eval ".sites[$i].port" "$sites_yaml")
        local root=$($YQ eval ".sites[$i].root" "$sites_yaml")
        local use_ssl=$($YQ eval ".sites[$i].ssl" "$sites_yaml")
        local template=$($YQ eval ".sites[$i].template" "$sites_yaml")
        local description=$($YQ eval ".sites[$i].description // \"Sin descripción\"" "$sites_yaml")
        
        echo "   🌐 Sitio [$((i+1))/$site_count]: $server_name:$port"
        
        # Desplegar HTML del sitio
        deploy_site_html "$ns" "$site_name" "$root" "$template" "$server_name"
        
        # Generar configuración nginx
        generate_nginx_site_config "$ns" "$site_name" "$server_name" "$port" "$root" "$use_ssl"
    done
    
    # 8. Lanzar Nginx
    ip netns exec "$ns" nginx -c "$BASE_DIR/lib/services/web/nginx.conf" -g "daemon on;"
    
    echo "✅ $site_count sitios web desplegados en $ns (Virtual Hosts)."
}