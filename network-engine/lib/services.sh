#!/bin/bash
# network-engine/lib/services.sh

ensure_service() {
  local svc="$1"
  local conf="$BASE_DIR/topology/services/$svc/service.conf"

  [[ -f "$conf" ]] || { echo "❌ Config $conf no existe"; return 1; }
  source "$conf"

  # 1. Prerrequisitos básicos del Namespace
  ip netns exec "$SERVICE_NAMESPACE" ip link set lo up
  ip netns exec "$SERVICE_NAMESPACE" mkdir -p "$SERVICE_ROOT"

  # 2. Lógica específica por tipo de servicio
  if [[ "$SERVICE_CMD" == *"nginx"* ]]; then
      # --- MÓDULO NGINX ---
      command -v nginx >/dev/null 2>&1 || dnf install -y nginx
      
      ip netns exec "$SERVICE_NAMESPACE" mkdir -p /var/log/nginx /var/lib/nginx /tmp/nginx/client_body
      
      # Copiar index.html si existe
      [[ -f "$BASE_DIR/topology/services/$svc/index.html" ]] && \
        ip netns exec "$SERVICE_NAMESPACE" cp "$BASE_DIR/topology/services/$svc/index.html" "$SERVICE_ROOT/index.html"

      local nginx_conf="/tmp/nginx_$SERVICE_NAME.conf"
      cat <<EOF > "$nginx_conf"
worker_processes 1;
user root; 
events { worker_connections 1024; }
http {
    include /etc/nginx/mime.types;
    access_log /var/log/nginx/access_$SERVICE_NAME.log;
    error_log /var/log/nginx/error_$SERVICE_NAME.log;
    client_body_temp_path /tmp/nginx_client_body;
    server {
        listen $SERVICE_PORT;
        server_name _;
        location / { root $SERVICE_ROOT; index index.html; }
    }
}
EOF
      # Reiniciar para aplicar cambios (idempotencia)
      ip netns exec "$SERVICE_NAMESPACE" pkill nginx 2>/dev/null
      ip netns exec "$SERVICE_NAMESPACE" nginx -c "$nginx_conf" -g "daemon on; pid /tmp/$SERVICE_NAME.pid;"

  elif [[ "$SERVICE_CMD" == *"dnsmasq"* ]]; then
      # --- MÓDULO DNSMASQ ---
      command -v dnsmasq >/dev/null 2>&1 || dnf install -y dnsmasq
      
      local hosts_file="/tmp/hosts_$SERVICE_NAME"
      printf "%s\n" "${DNS_RECORDS[@]}" > "$hosts_file"
      
      # Matar instancia previa e iniciar
      ip netns exec "$SERVICE_NAMESPACE" pkill dnsmasq 2>/dev/null
      ip netns exec "$SERVICE_NAMESPACE" dnsmasq \
          --listen-address=0.0.0.0 \
          --no-hosts \
          --addn-hosts="$hosts_file" \
          --pid-file="/tmp/dnsmasq.pid"
  fi

  # 3. Verificación final de socket
  sleep 1
  if ip netns exec "$SERVICE_NAMESPACE" ss -tulpn | grep -q ":$SERVICE_PORT"; then
    echo "✅ $SERVICE_NAME iniciado correctamente en puerto $SERVICE_PORT"
  else
    echo "❌ Error: $SERVICE_NAME no responde en puerto $SERVICE_PORT"
    return 1
  fi
}