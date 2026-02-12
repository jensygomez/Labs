#!/bin/bash
# network-engine/lib/services/nginx.sh
# 🌐 MÓDULO NGINX - Web Server

#═══════════════════════════════════════════════════════════════════
# INSTALACIÓN
#═══════════════════════════════════════════════════════════════════
install_nginx() {
  echo "📦 Verificando nginx..."
  
  if command -v nginx >/dev/null 2>&1; then
    local version=$(nginx -v 2>&1 | cut -d'/' -f2)
    echo "   ✓ nginx ya instalado (versión: $version)"
    return 0
  fi
  
  echo "   ⏳ Instalando nginx..."
  if dnf install -y nginx >/dev/null 2>&1; then
    echo "   ✓ nginx instalado correctamente"
    return 0
  else
    echo "   ❌ Error al instalar nginx"
    return 1
  fi
}

#═══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
#═══════════════════════════════════════════════════════════════════
configure_nginx() {
  local svc="$1"
  local nginx_conf="/tmp/nginx_$SERVICE_NAME.conf"
  
  echo "⚙️  Configurando nginx..."
  
  # 1. Crear directorios necesarios en el namespace
  echo "   • Creando directorios..."
  ip netns exec "$SERVICE_NAMESPACE" mkdir -p \
    /var/log/nginx \
    /var/lib/nginx \
    /tmp/nginx/client_body 2>/dev/null
  
  # 2. Copiar o generar contenido web
  echo "   • Preparando contenido web..."
  local source_html="$BASE_DIR/topology/services/$svc/index.html"
  
  if [[ -f "$source_html" ]]; then
    echo "     ✓ Copiando index.html personalizado"
    cp "$source_html" "$SERVICE_ROOT/index.html" || {
      echo "     ❌ Error copiando index.html"
      return 1
    }
  else
    echo "     ⚠️  No hay index.html, generando default..."
    cat > "$SERVICE_ROOT/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>$SERVICE_NAME</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            text-align: center; 
            margin-top: 100px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            background: rgba(255,255,255,0.1);
            padding: 40px;
            border-radius: 10px;
            display: inline-block;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 $SERVICE_NAME</h1>
        <p>Servicio activo en namespace: <strong>$SERVICE_NAMESPACE</strong></p>
        <p>Puerto: <strong>$SERVICE_PORT</strong></p>
        <hr>
        <small>Network Engine Lab • Rocky Linux 9</small>
    </div>
</body>
</html>
EOF
  fi
  
  # 3. Generar configuración de nginx
  echo "   • Generando nginx.conf: $nginx_conf"
  cat > "$nginx_conf" <<EOF
# Nginx configuration for $SERVICE_NAME
# Generated: $(date)

worker_processes 1;
user root;
pid /tmp/nginx_$SERVICE_NAME.pid;
error_log /var/log/nginx/error_$SERVICE_NAME.log warn;

events { 
    worker_connections 1024; 
}

http {
    # MIME types
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    access_log /var/log/nginx/access_$SERVICE_NAME.log;
    
    # Temp paths
    client_body_temp_path /tmp/nginx/client_body;
    proxy_temp_path /tmp/nginx/proxy;
    fastcgi_temp_path /tmp/nginx/fastcgi;
    uwsgi_temp_path /tmp/nginx/uwsgi;
    scgi_temp_path /tmp/nginx/scgi;
    
    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    
    # Server block
    server {
        listen $SERVICE_PORT;
        server_name _;
        
        # Document root
        root $SERVICE_ROOT;
        index index.html index.htm;
        
        # Main location
        location / {
            try_files \$uri \$uri/ =404;
        }
        
        # Error pages
        error_page 404 /404.html;
        error_page 500 502 503 504 /50x.html;
    }
}
EOF

  # 4. Validar configuración
  echo "   • Testeando configuración..."
  if ip netns exec "$SERVICE_NAMESPACE" nginx -t -c "$nginx_conf" 2>&1 | grep -q "successful"; then
    echo "     ✓ Configuración válida"
    return 0
  else
    echo "     ❌ Configuración inválida:"
    ip netns exec "$SERVICE_NAMESPACE" nginx -t -c "$nginx_conf" 2>&1 | sed 's/^/       /'
    return 1
  fi
}

#═══════════════════════════════════════════════════════════════════
# INICIO
#═══════════════════════════════════════════════════════════════════
start_nginx() {
  local nginx_conf="/tmp/nginx_$SERVICE_NAME.conf"
  
  echo "🚀 Iniciando nginx..."
  
  # 1. Matar instancia previa si existe
  echo "   • Verificando instancias previas..."
  if ip netns exec "$SERVICE_NAMESPACE" pkill -0 -f "nginx.*$SERVICE_NAME" 2>/dev/null; then
    echo "     ⚠️  Deteniendo instancia previa..."
    ip netns exec "$SERVICE_NAMESPACE" pkill -f "nginx.*$SERVICE_NAME" 2>/dev/null || true
    sleep 0.5
  else
    echo "     ✓ No hay instancias previas"
  fi
  
  # 2. Iniciar nginx en background
  echo "   • Lanzando proceso..."
  if ip netns exec "$SERVICE_NAMESPACE" bash -c "nginx -c '$nginx_conf' 2>/var/log/nginx/startup_$SERVICE_NAME.log &"; then
    echo "     ✓ Comando ejecutado"
    sleep 0.5
    
    # Verificar que el proceso arrancó
    if ip netns exec "$SERVICE_NAMESPACE" pgrep -f "nginx.*$SERVICE_NAME" >/dev/null 2>&1; then
      echo "     ✓ Proceso nginx activo"
      return 0
    else
      echo "     ❌ Proceso nginx no está corriendo"
      echo ""
      echo "   📄 Logs de startup:"
      cat "/var/log/nginx/startup_$SERVICE_NAME.log" 2>/dev/null | sed 's/^/       /' || echo "       (no disponible)"
      return 1
    fi
  else
    echo "     ❌ Error ejecutando nginx"
    return 1
  fi
}

#═══════════════════════════════════════════════════════════════════
# GESTIÓN (FUNCIONES OPCIONALES)
#═══════════════════════════════════════════════════════════════════

# Recargar configuración sin downtime
reload_nginx() {
  local nginx_conf="/tmp/nginx_$SERVICE_NAME.conf"
  echo "🔄 Recargando nginx..."
  ip netns exec "$SERVICE_NAMESPACE" nginx -s reload -c "$nginx_conf"
}

# Detener nginx limpiamente
stop_nginx() {
  echo "🛑 Deteniendo nginx..."
  ip netns exec "$SERVICE_NAMESPACE" pkill -f "nginx.*$SERVICE_NAME" 2>/dev/null
  if [[ $? -eq 0 ]]; then
    echo "   ✓ Nginx detenido"
  else
    echo "   ⚠️  Nginx no estaba corriendo"
  fi
}

# Verificar estado
status_nginx() {
  if ip netns exec "$SERVICE_NAMESPACE" pgrep -f "nginx.*$SERVICE_NAME" >/dev/null 2>&1; then
    echo "✅ nginx está corriendo"
    ip netns exec "$SERVICE_NAMESPACE" ps aux | grep -v grep | grep "nginx.*$SERVICE_NAME"
  else
    echo "❌ nginx no está corriendo"
  fi
}