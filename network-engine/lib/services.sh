#!/bin/bash
# network-engine/lib/services.sh
# ✅ FRAMEWORK CORE - Sistema modular de servicios

# Directorio de módulos de servicios
SERVICE_MODULES_DIR="$BASE_DIR/lib/services"

#═══════════════════════════════════════════════════════════════════
# FUNCIÓN PRINCIPAL - Orquestador de servicios
#═══════════════════════════════════════════════════════════════════
ensure_service() {
  local svc="$1"
  local conf="$BASE_DIR/topology/services/$svc/service.conf"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔍 Iniciando servicio: $svc"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # 1. Validar que existe la configuración
  if [[ ! -f "$conf" ]]; then
    echo "❌ Config no encontrada: $conf"
    ls -la "$BASE_DIR/topology/services/$svc/" 2>/dev/null || echo "❌ Directorio $svc no existe"
    return 1
  fi
  
  # 2. Cargar configuración del servicio
  echo "📄 Cargando config: $conf"
  source "$conf" || { 
    echo "❌ Error al cargar configuración" 
    return 1 
  }
  echo "✅ Config cargada:"
  echo "   • Nombre: $SERVICE_NAME"
  echo "   • Namespace: $SERVICE_NAMESPACE"
  echo "   • Puerto: $SERVICE_PORT"
  echo "   • Comando: $SERVICE_CMD"

  # 3. Determinar el tipo de servicio y cargar módulo específico
  local service_type=$(detect_service_type "$SERVICE_CMD")
  local module_file="$SERVICE_MODULES_DIR/${service_type}.sh"
  
  echo ""
  echo "🔌 Detectado tipo: $service_type"
  
  if [[ ! -f "$module_file" ]]; then
    echo "❌ Módulo no encontrado: $module_file"
    echo "💡 Módulos disponibles:"
    ls -1 "$SERVICE_MODULES_DIR"/*.sh 2>/dev/null | xargs -n1 basename || echo "   (ninguno)"
    return 1
  fi
  
  echo "📦 Cargando módulo: $module_file"
  source "$module_file" || {
    echo "❌ Error al cargar módulo"
    return 1
  }

  # 4. Prerrequisitos básicos del namespace (común a todos)
  echo ""
  setup_namespace_basics "$SERVICE_NAMESPACE" "$SERVICE_ROOT" || return 1
  
  # 5. Instalar dependencias del servicio (función del módulo)
  echo ""
  install_${service_type} || { 
    echo "❌ Error instalando dependencias de $service_type" 
    return 1 
  }
  
  # 6. Configurar servicio (función del módulo)
  echo ""
  configure_${service_type} "$svc" || { 
    echo "❌ Error configurando $service_type" 
    return 1 
  }
  
  # 7. Iniciar servicio (función del módulo)
  echo ""
  start_${service_type} || { 
    echo "❌ Error iniciando $service_type" 
    return 1 
  }
  
  # 8. Verificar que está corriendo
  echo ""
  verify_service "$SERVICE_NAMESPACE" "$SERVICE_PORT" "$SERVICE_NAME" || return 1
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Servicio $svc iniciado correctamente"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

#═══════════════════════════════════════════════════════════════════
# FUNCIONES AUXILIARES COMUNES
#═══════════════════════════════════════════════════════════════════

# Detectar tipo de servicio basado en el comando
detect_service_type() {
  local cmd="$1"
  case "$cmd" in
    *nginx*)      echo "nginx" ;;
    *dnsmasq*)    echo "dnsmasq" ;;
    *postgres*)   echo "postgresql" ;;
    *apache*)     echo "apache" ;;
    *haproxy*)    echo "haproxy" ;;
    *bind*)       echo "bind" ;;
    *mysql*)      echo "mysql" ;;
    *)            echo "generic" ;;
  esac
}

# Configuración básica del namespace (común a todos los servicios)
setup_namespace_basics() {
  local ns="$1"
  local root="$2"
  
  echo "🔧 Configurando namespace: $ns"
  
  # Levantar loopback
  if ip netns exec "$ns" ip link set lo up 2>/dev/null; then
    echo "   ✓ Loopback activado"
  else
    echo "   ⚠️  Loopback ya estaba activo"
  fi
  
  # Crear directorio root del servicio
  if ip netns exec "$ns" mkdir -p "$root" 2>/dev/null; then
    echo "   ✓ Directorio root: $root"
  else
    echo "   ⚠️  Directorio root ya existía"
  fi
  
  return 0
}

# Verificación genérica de servicios
verify_service() {
  local ns="$1"
  local port="$2"
  local name="$3"
  
  echo "👁️  Verificando servicio..."
  echo "   • Namespace: $ns"
  echo "   • Puerto esperado: $port"
  echo "   • Timeout: 2 segundos"
  
  sleep 2
  
  # Verificar que el puerto está escuchando
  if ip netns exec "$ns" ss -tulpn 2>/dev/null | grep -q ":${port} "; then
    echo ""
    echo "✅ $name escuchando en puerto $port"
    
    # Mostrar info del socket
    echo ""
    echo "📊 Info del socket:"
    ip netns exec "$ns" ss -tulpn 2>/dev/null | grep ":${port} " | sed 's/^/   /'
    return 0
  else
    echo ""
    echo "❌ Error: $name NO responde en puerto $port"
    echo ""
    echo "🔍 DEBUG - Sockets activos en $ns:"
    local sockets=$(ip netns exec "$ns" ss -tulpn 2>/dev/null)
    if [[ -n "$sockets" ]]; then
      echo "$sockets" | sed 's/^/   /'
    else
      echo "   (ninguno)"
    fi
    
    echo ""
    echo "🔍 DEBUG - Procesos en $ns:"
    ip netns exec "$ns" ps aux | head -10 | sed 's/^/   /'
    
    echo ""
    echo "🔍 DEBUG - Logs recientes:"
    if [[ -f "/var/log/nginx/error_${name}.log" ]]; then
      tail -5 "/var/log/nginx/error_${name}.log" 2>/dev/null | sed 's/^/   /' || echo "   (no disponible)"
    elif [[ -f "/var/log/dnsmasq_${name}.log" ]]; then
      tail -5 "/var/log/dnsmasq_${name}.log" 2>/dev/null | sed 's/^/   /' || echo "   (no disponible)"
    fi
    
    return 1
  fi
}

#═══════════════════════════════════════════════════════════════════
# FUNCIONES DE GESTIÓN (OPCIONALES)
#═══════════════════════════════════════════════════════════════════

# Lista todos los servicios disponibles
list_available_services() {
  echo "📋 Servicios disponibles:"
  local services_dir="$BASE_DIR/topology/services"
  if [[ -d "$services_dir" ]]; then
    for svc_dir in "$services_dir"/*; do
      if [[ -d "$svc_dir" ]]; then
        local svc_name=$(basename "$svc_dir")
        if [[ -f "$svc_dir/service.conf" ]]; then
          echo "   ✓ $svc_name"
        else
          echo "   ⚠️  $svc_name (sin service.conf)"
        fi
      fi
    done
  else
    echo "   (ninguno)"
  fi
}

# Lista módulos disponibles
list_available_modules() {
  echo "🔌 Módulos disponibles:"
  if [[ -d "$SERVICE_MODULES_DIR" ]]; then
    for module in "$SERVICE_MODULES_DIR"/*.sh; do
      if [[ -f "$module" ]]; then
        local module_name=$(basename "$module" .sh)
        echo "   • $module_name"
      fi
    done
  else
    echo "   (ninguno)"
  fi
}