#!/bin/bash
# network-engine/lib/services/dnsmasq.sh
# 🌐 MÓDULO DNSMASQ - DNS Server

#═══════════════════════════════════════════════════════════════════
# INSTALACIÓN
#═══════════════════════════════════════════════════════════════════
install_dnsmasq() {
  echo "📦 Verificando dnsmasq..."
  
  if command -v dnsmasq >/dev/null 2>&1; then
    local version=$(dnsmasq --version 2>&1 | head -1 | awk '{print $3}')
    echo "   ✓ dnsmasq ya instalado (versión: $version)"
    return 0
  fi
  
  echo "   ⏳ Instalando dnsmasq..."
  if dnf install -y dnsmasq >/dev/null 2>&1; then
    echo "   ✓ dnsmasq instalado correctamente"
    return 0
  else
    echo "   ❌ Error al instalar dnsmasq"
    return 1
  fi
}

#═══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
#═══════════════════════════════════════════════════════════════════
configure_dnsmasq() {
  local svc="$1"
  local hosts_file="/tmp/hosts_$SERVICE_NAME"
  local dnsmasq_conf="/tmp/dnsmasq_$SERVICE_NAME.conf"
  
  echo "⚙️  Configurando dnsmasq..."
  
  # 1. Validar que existen DNS_RECORDS
  if [[ -z "${DNS_RECORDS[*]}" ]]; then
    echo "   ❌ No hay DNS_RECORDS definidos en service.conf"
    return 1
  fi
  
  # 2. Generar archivo hosts
  echo "   • Generando archivo hosts: $hosts_file"
  printf "%s\n" "${DNS_RECORDS[@]}" > "$hosts_file"
  
  echo "   • Registros DNS configurados:"
  printf '%s\n' "${DNS_RECORDS[@]}" | sed 's/^/     /'
  
  # 3. Generar configuración de dnsmasq
  echo "   • Generando dnsmasq.conf: $dnsmasq_conf"
  cat > "$dnsmasq_conf" <<EOF
# dnsmasq configuration for $SERVICE_NAME
# Generated: $(date)

# Bind settings
listen-address=0.0.0.0
port=$SERVICE_PORT
bind-interfaces

# DNS settings
no-resolv
no-poll
no-hosts
addn-hosts=$hosts_file

# Cache settings
cache-size=1000

# Logging
log-queries
log-facility=/var/log/dnsmasq_$SERVICE_NAME.log

# PID file
pid-file=/tmp/dnsmasq_$SERVICE_NAME.pid

# Don't read /etc/resolv.conf
no-resolv

# Security
user=root
EOF

  echo "     ✓ Configuración generada"
  return 0
}

#═══════════════════════════════════════════════════════════════════
# INICIO
#═══════════════════════════════════════════════════════════════════
start_dnsmasq() {
  local dnsmasq_conf="/tmp/dnsmasq_$SERVICE_NAME.conf"
  local pid_file="/tmp/dnsmasq_$SERVICE_NAME.pid"
  local log_file="/var/log/dnsmasq_$SERVICE_NAME.log"
  
  echo "🚀 Iniciando dnsmasq..."
  
  # 1. Matar instancia previa si existe
  echo "   • Verificando instancias previas..."
  if ip netns exec "$SERVICE_NAMESPACE" pkill -0 -f "dnsmasq.*$SERVICE_NAME" 2>/dev/null; then
    echo "     ⚠️  Deteniendo instancia previa..."
    ip netns exec "$SERVICE_NAMESPACE" pkill -f "dnsmasq.*$SERVICE_NAME" 2>/dev/null || true
    sleep 0.5
  else
    echo "     ✓ No hay instancias previas"
  fi
  
  # 2. Limpiar PID file antiguo
  rm -f "$pid_file" 2>/dev/null
  
  # 3. Iniciar dnsmasq en background
  echo "   • Lanzando proceso..."
  
  # Usando la config file (más limpio)
  if ip netns exec "$SERVICE_NAMESPACE" bash -c "dnsmasq -C '$dnsmasq_conf' &"; then
    echo "     ✓ Comando ejecutado"
    sleep 1
    
    # Verificar que el proceso arrancó
    if ip netns exec "$SERVICE_NAMESPACE" pgrep -f "dnsmasq.*$SERVICE_NAME" >/dev/null 2>&1; then
      echo "     ✓ Proceso dnsmasq activo"
      
      # Mostrar PID
      local pid=$(cat "$pid_file" 2>/dev/null)
      if [[ -n "$pid" ]]; then
        echo "     ✓ PID: $pid"
      fi
      
      return 0
    else
      echo "     ❌ Proceso dnsmasq no está corriendo"
      echo ""
      echo "   📄 Logs recientes:"
      tail -10 "$log_file" 2>/dev/null | sed 's/^/       /' || echo "       (no disponible)"
      return 1
    fi
  else
    echo "     ❌ Error ejecutando dnsmasq"
    return 1
  fi
}

#═══════════════════════════════════════════════════════════════════
# GESTIÓN (FUNCIONES OPCIONALES)
#═══════════════════════════════════════════════════════════════════

# Detener dnsmasq limpiamente
stop_dnsmasq() {
  echo "🛑 Deteniendo dnsmasq..."
  ip netns exec "$SERVICE_NAMESPACE" pkill -f "dnsmasq.*$SERVICE_NAME" 2>/dev/null
  if [[ $? -eq 0 ]]; then
    echo "   ✓ dnsmasq detenido"
    rm -f "/tmp/dnsmasq_$SERVICE_NAME.pid" 2>/dev/null
  else
    echo "   ⚠️  dnsmasq no estaba corriendo"
  fi
}

# Verificar estado
status_dnsmasq() {
  if ip netns exec "$SERVICE_NAMESPACE" pgrep -f "dnsmasq.*$SERVICE_NAME" >/dev/null 2>&1; then
    echo "✅ dnsmasq está corriendo"
    ip netns exec "$SERVICE_NAMESPACE" ps aux | grep -v grep | grep "dnsmasq.*$SERVICE_NAME"
    
    # Mostrar stats si está activo
    echo ""
    echo "📊 Estadísticas:"
    local log_file="/var/log/dnsmasq_$SERVICE_NAME.log"
    if [[ -f "$log_file" ]]; then
      echo "   • Queries recientes:"
      grep "query" "$log_file" 2>/dev/null | tail -5 | sed 's/^/     /' || echo "     (ninguno)"
    fi
  else
    echo "❌ dnsmasq no está corriendo"
  fi
}

# Test de resolución DNS
test_dnsmasq() {
  echo "🧪 Testeando resolución DNS..."
  
  # Extraer un hostname del archivo hosts para testear
  local hosts_file="/tmp/hosts_$SERVICE_NAME"
  local test_host=$(grep -v "^#" "$hosts_file" 2>/dev/null | head -1 | awk '{print $2}')
  
  if [[ -z "$test_host" ]]; then
    echo "   ⚠️  No hay hosts configurados para testear"
    return 0
  fi
  
  echo "   • Testeando resolución de: $test_host"
  
  # Obtener la IP del namespace donde corre dnsmasq
  local dns_ip=$(ip netns exec "$SERVICE_NAMESPACE" ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -1)
  
  if [[ -z "$dns_ip" ]]; then
    echo "   ❌ No se pudo obtener IP del namespace"
    return 1
  fi
  
  echo "   • DNS server: $dns_ip:$SERVICE_PORT"
  
  # Test con dig o nslookup
  if command -v dig >/dev/null 2>&1; then
    ip netns exec "$SERVICE_NAMESPACE" dig @127.0.0.1 -p "$SERVICE_PORT" "$test_host" +short
  elif command -v nslookup >/dev/null 2>&1; then
    ip netns exec "$SERVICE_NAMESPACE" nslookup "$test_host" "127.0.0.1#$SERVICE_PORT"
  else
    echo "   ⚠️  dig/nslookup no disponibles para test"
  fi
}