#!/bin/bash
# network-engine/lib/services.sh

ensure_service() {
  local svc="$1"
  local conf="$BASE_DIR/topology/services/$svc/service.conf"
  # Instalar NGINX si no está instalado
  command -v nginx >/dev/null 2>&1 || dnf install -y nginx

  [[ -f "$conf" ]] || { echo "❌ Config $conf no existe"; return 1; }
  source "$conf"

  # 1. Asegurar loopback UP (vital para que Nginx bindeé el socket)
  ip netns exec "$SERVICE_NAMESPACE" ip link set lo up

  # 2. Preparar directorios y asegurar que el usuario nginx pueda escribir
  # En Namespaces, a veces es más fácil correr como root para evitar líos de permisos
  ip netns exec "$SERVICE_NAMESPACE" mkdir -p "$SERVICE_ROOT"
  ip netns exec "$SERVICE_NAMESPACE" mkdir -p /var/log/nginx /var/lib/nginx /tmp/nginx/client_body

  # 3. Copiar index.html
  if [[ -f "$BASE_DIR/topology/services/$svc/index.html" ]]; then
    ip netns exec "$SERVICE_NAMESPACE" cp \
      "$BASE_DIR/topology/services/$svc/index.html" \
      "$SERVICE_ROOT/index.html"
  fi

  # 4. Verificar si ya está corriendo
  if ip netns exec "$SERVICE_NAMESPACE" ss -tln | grep -q ":$SERVICE_PORT"; then
    echo "✅ Servicio $SERVICE_NAME ya activo en puerto $SERVICE_PORT"
    return 0
  fi

  # 5. Generar config mínima optimizada para Namespaces
  local nginx_conf="/tmp/nginx_$SERVICE_NAME.conf"
  cat <<EOF > "$nginx_conf"
worker_processes 1;
# Correr como root dentro del netns simplifica permisos de archivos
user root; 
events { worker_connections 1024; }
http {
    include /etc/nginx/mime.types;
    access_log /var/log/nginx/access_$SERVICE_NAME.log;
    error_log /var/log/nginx/error_$SERVICE_NAME.log;
    
    # Rutas temporales para evitar choques con el host
    client_body_temp_path /tmp/nginx_client_body;
    proxy_temp_path /tmp/nginx_proxy;
    fastcgi_temp_path /tmp/nginx_fastcgi;

    server {
        listen $SERVICE_PORT;
        server_name _;
        location / {
            root $SERVICE_ROOT;
            index index.html;
        }
    }
}
EOF

  echo "🚀 Iniciando $SERVICE_NAME (Nginx) en puerto $SERVICE_PORT..."
  
  # 6. Ejecución: Usamos -g 'pid ...' para asegurar que el PID sea único por servicio
  ip netns exec "$SERVICE_NAMESPACE" nginx -c "$nginx_conf" -g "daemon on; pid /tmp/$SERVICE_NAME.pid;"
  
  sleep 1
  if ip netns exec "$SERVICE_NAMESPACE" ss -tln | grep -q ":$SERVICE_PORT"; then
    echo "✅ $SERVICE_NAME iniciado correctamente"
  else
    echo "❌ Falló el inicio. Log de error:"
    ip netns exec "$SERVICE_NAMESPACE" cat "/var/log/nginx/error_$SERVICE_NAME.log"
  fi

  # Configuracion del DNS
  if [[ "$SERVICE_CMD" == "dnsmasq" ]]; then
    echo "🚀 Configurando DNS Record: ${DNS_RECORDS[@]}"
    local hosts_file="/tmp/hosts_$SERVICE_NAME"
    printf "%s\n" "${DNS_RECORDS[@]}" > "$hosts_file"
    
    # Arrancar dnsmasq apuntando a nuestro archivo de hosts
    ip netns exec "$SERVICE_NAMESPACE" dnsmasq \
        --no-daemon \
        --listen-address=0.0.0.0 \
        --no-hosts \
        --addn-hosts="$hosts_file" &
fi
}