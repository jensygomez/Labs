#!/bin/bash
# network-engine/lib/services.sh


ensure_service() {
  local svc="$1"
  local conf="$BASE_DIR/topology/services/$svc/service.conf"

  [[ -f "$conf" ]] || { echo "❌ Config $conf no existe"; return 1; }
  source "$conf"

  # 1. Asegurar loopback UP (vital para Nginx)
  ip netns exec "$SERVICE_NAMESPACE" ip link set lo up

  # 2. Preparar directorios
  ip netns exec "$SERVICE_NAMESPACE" mkdir -p "$SERVICE_ROOT"
  ip netns exec "$SERVICE_NAMESPACE" mkdir -p /var/log/nginx /var/lib/nginx

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

  # 5. Generar config mínima de Nginx para el namespace
  local nginx_conf="/tmp/nginx_$SERVICE_NAME.conf"
  cat <<EOF > "$nginx_conf"
error_log /var/log/nginx/error.log;
pid /run/nginx_$SERVICE_NAME.pid;
events { worker_connections 1024; }
http {
    access_log /var/log/nginx/access_$SERVICE_NAME.log;
    server {
        listen $SERVICE_PORT;
        server_name localhost;
        location / {
            root $SERVICE_ROOT;
            index index.html;
        }
    }
}
EOF

  echo "🚀 Iniciando $SERVICE_NAME (Nginx) en puerto $SERVICE_PORT..."
  
  # Ejecutar Nginx dentro del namespace
  ip netns exec "$SERVICE_NAMESPACE" nginx -c "$nginx_conf" -g "daemon on;"
  
  sleep 1
  if ip netns exec "$SERVICE_NAMESPACE" ss -tln | grep -q ":$SERVICE_PORT"; then
    echo "✅ $SERVICE_NAME iniciado correctamente"
  else
    echo "❌ Falló el inicio de $SERVICE_NAME. Revisa 'ip netns exec $SERVICE_NAMESPACE dmesg'"
  fi
}