#!/bin/bash
# network-engine/lib/services.sh

SERVICES=()

ensure_service() {
  local svc="$1"
  local conf="$BASE_DIR/topology/services/$svc/service.conf"

  [[ -f "$conf" ]] || { echo "❌ Config $conf no existe"; return 1; }
  source "$conf"

  # Verificar que el namespace existe
  if ! ns_exists "$SERVICE_NAMESPACE"; then
    echo "❌ Namespace $SERVICE_NAMESPACE no existe para servicio $svc"
    return 1
  fi

  # Crear directorio si no existe
  ip netns exec "$SERVICE_NAMESPACE" mkdir -p "$SERVICE_ROOT"

  # Copiar archivos web
  if [[ -f "$BASE_DIR/topology/services/$svc/index.html" ]]; then
    ip netns exec "$SERVICE_NAMESPACE" cp \
      "$BASE_DIR/topology/services/$svc/index.html" \
      "$SERVICE_ROOT/index.html"
  fi

  # Verificar si ya está corriendo
  if ip netns exec "$SERVICE_NAMESPACE" ss -tln | grep -q ":$SERVICE_PORT"; then
    echo "✅ Servicio $SERVICE_NAME ya activo"
    return 0
  fi

  echo "🚀 Iniciando $SERVICE_NAME en puerto $SERVICE_PORT..."
  
  # SOLUCIÓN: Usar screen o tminkeeper en lugar de nohup
  ip netns exec "$SERVICE_NAMESPACE" \
    sh -c "cd $SERVICE_ROOT && $SERVICE_CMD &" 2>/dev/null
  
  # Esperar un momento y verificar
  sleep 0.5
  if ip netns exec "$SERVICE_NAMESPACE" ss -tln | grep -q ":$SERVICE_PORT"; then
    echo "✅ $SERVICE_NAME iniciado correctamente"
  else
    echo "⚠️  $SERVICE_NAME podría no haberse iniciado"
  fi
}