#!/bin/bash
# network-engine/lib/services.sh
# ✅ VERSIÓN CORREGIDA CON DEBUG Y ERROR HANDLING

ensure_service() {
  local svc="$1"
  local conf="$BASE_DIR/topology/services/$svc/service.conf"

  echo "🔍 Buscando config: $conf"
  
  [[ -f "$conf" ]] || { 
    echo "❌ Config $conf no existe" 
    ls -la "$BASE_DIR/topology/services/$svc/" 2>/dev/null || echo "❌ Directorio $svc no existe"
    return 1 
  }
  
  source "$conf" || { echo "❌ Error sourcing $conf"; return 1; }
  echo "✅ Config $svc cargada: $SERVICE_NAME en $SERVICE_NAMESPACE:$SERVICE_PORT"

  # 1. Prerrequisitos básicos del Namespace
  echo "🔧 Configurando prerrequisitos en $SERVICE_NAMESPACE..."
  ip netns exec "$SERVICE_NAMESPACE" ip link set lo up || echo "⚠️  lo ya estaba UP"
  ip netns exec "$SERVICE_NAMESPACE" mkdir -p "$SERVICE_ROOT" || true

  # 2. Lógica específica por tipo de servicio
  if [[ "$SERVICE_CMD" == *"nginx"* ]]; then
      # --- MÓDULO NGINX ---
      echo "📦 Instalando nginx si es necesario..."
      command -v nginx >/dev/null 2>&1 || dnf install -y nginx
      
      ip netns exec "$SERVICE_NAMESPACE" mkdir -p /var/log/nginx /var/lib/nginx /tmp/nginx/client_body
      
      # Copiar index.html si existe
      if [[ -f "$BASE_DIR/topology/services/$svc/index.html" ]]; then
        echo "📄 Copiando index.html a $SERVICE_ROOT/"
        ip netns exec "$SERVICE_NAMESPACE" cp "$BASE_DIR/topology/services/$svc/index.html" "$SERVICE_ROOT/index.html"
      else
        echo "⚠️  index.html no encontrado en $BASE_DIR/topology/services/$svc/"
        ip netns exec "$SERVICE_NAMESPACE" echo '<h1>$SERVICE_NAME OK!</h1>' > "$SERVICE_ROOT/index.html"
      fi

      local nginx_conf="/tmp/nginx_$SERVICE_NAME.conf"
      echo "📝 Generando nginx.conf en $nginx_conf"
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
      
      # 🔧 FIX: Test + start CON ERROR HANDLING
      echo "🧪 Testeando nginx config..."
      ip netns exec "$SERVICE_NAMESPACE" pkill nginx 2>/dev/null
      if ! ip netns exec "$SERVICE_NAMESPACE" nginx -t -c "$nginx_conf" >/dev/null 2>&1; then
        echo "❌ Nginx config test FAILED para $SERVICE_NAME"
        ip netns exec "$SERVICE_NAMESPACE" nginx -t -c "$nginx_conf"
        return 1
      fi
      
      echo "🚀 Iniciando nginx..."
      if ! ip netns exec "$SERVICE_NAMESPACE" nginx -c "$nginx_conf" -g "daemon on; pid /tmp/$SERVICE_NAME.pid;" >/dev/null 2>&1; then
        echo "❌ Nginx FAILED to start en $SERVICE_NAMESPACE"
        ip netns exec "$SERVICE_NAMESPACE" nginx -c "$nginx_conf" -g "daemon off;" 2>&1 || true
        return 1
      fi
      echo "✅ Nginx comando ejecutado (verificación en 2s...)"

  elif [[ "$SERVICE_CMD" == *"dnsmasq"* ]]; then
      # --- MÓDULO DNSMASQ ---
      echo "📦 Instalando dnsmasq si es necesario..."
      command -v dnsmasq >/dev/null 2>&1 || dnf install -y dnsmasq
      
      local hosts_file="/tmp/hosts_$SERVICE_NAME"
      echo "📝 Generando hosts_file: $hosts_file"
      printf "%s\n" "${DNS_RECORDS[@]}" > "$hosts_file"
      echo "DNS records:"
      printf '  %s\n' "${DNS_RECORDS[@]}"
      
      # Matar instancia previa e iniciar
      ip netns exec "$SERVICE_NAMESPACE" pkill dnsmasq 2>/dev/null
      echo "🚀 Iniciando dnsmasq..."
      if ! ip netns exec "$SERVICE_NAMESPACE" dnsmasq \
          --listen-address=0.0.0.0 \
          --no-hosts \
          --addn-hosts="$hosts_file" \
          --pid-file="/tmp/dnsmasq.pid" >/dev/null 2>&1; then
        echo "❌ dnsmasq FAILED to start"
        return 1
      fi
      echo "✅ dnsmasq comando ejecutado"
  fi

  # 3. Verificación final de socket (FIX para puerto 53 y mejor grep)
  echo "👁️  Verificando socket en puerto $SERVICE_PORT (2s)..."
  sleep 2
  if ip netns exec "$SERVICE_NAMESPACE" ss -tulpn 2>/dev/null | grep -q ":${SERVICE_PORT} "; then
    echo "✅ $SERVICE_NAME iniciado correctamente en puerto $SERVICE_PORT"
  else
    echo "❌ Error: $SERVICE_NAME no responde en puerto $SERVICE_PORT"
    echo "🔍 DEBUG ss output:"
    ip netns exec "$SERVICE_NAMESPACE" ss -tulpn 2>/dev/null || echo "No processes listening"
    echo "🔍 Procs en namespace:"
    ip netns exec "$SERVICE_NAMESPACE" ps aux
    return 1
  fi
}
