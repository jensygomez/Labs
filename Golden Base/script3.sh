#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux 9.7)
# SCRIPT:   3 de 5 - Despliegue de Servicios Web (Capa de Aplicación)
# ============================================================================
#
# OBJETIVO:
#   Desplegar un servicio Web (Nginx) en la sede Alemania (NS-SERVICES),
#   validando el control de acceso desde China (NS-CLIENT) y SysAdmin
#   (NS-SYSADMIN), sobre la infraestructura creada en el Script 2.
#
# MODELO OPERATIVO (IMPORTANTE):
#   - Nginx se instala en el HOST.
#   - El proceso se ejecuta dentro del namespace NS-SERVICES usando
#     `ip netns exec`.
#   - Esto simula un servidor remoto SIN usar contenedores ni VMs.
#
# PRERREQUISITOS:
#   - Script 2 ejecutado y activo.
#   - Namespaces existentes:
#       NS-SERVICES, NS-CLIENT, NS-SYSADMIN
# ============================================================================

set -e

echo "=== 🖥️  SCRIPT 3: CAPA DE APLICACIÓN (WEB) ==="
echo "📅 Fecha: $(date)"

# ============================================================================
# [1/5] Validaciones Previas (Fail Fast)
# ============================================================================
for ns in NS-SERVICES NS-CLIENT NS-SYSADMIN; do
  ip netns list | grep -qw "$ns" || {
    echo "❌ Namespace requerido no encontrado: $ns"
    exit 1
  }
done

# ============================================================================
# [2/5] Instalación de Paquetes en el Host
# ============================================================================
echo "📦 Instalando Nginx (host)..."
dnf install -y nginx >/dev/null

# ============================================================================
# [3/5] Contenido Web (Alemania)
# ============================================================================
echo "🌐 Desplegando contenido web corporativo (Alemania)..."

WEB_ROOT="/var/www/ns-services"
mkdir -p "$WEB_ROOT"

cat > "$WEB_ROOT/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>Sede Central - Alemania</title>
  <style>
    body {
      font-family: sans-serif;
      background: #1f2d3d;
      color: #ecf0f1;
      text-align: center;
      padding-top: 60px;
    }
    .status {
      background: #27ae60;
      display: inline-block;
      padding: 12px 18px;
      border-radius: 6px;
      font-weight: bold;
    }
  </style>
</head>
<body>
  <h1>🇩🇪 Sede Central - Alemania</h1>
  <div class="status">SERVICIO WEB OPERATIVO</div>
  <p>IP del Servicio: <strong>10.10.0.10</strong></p>
  <hr>
  <small>Golden Image Lab — Capa de Aplicación</small>
</body>
</html>
EOF

chown -R nginx:nginx "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

# ============================================================================
# [4/5] Configuración de Nginx (Bind explícito al Namespace)
# ============================================================================
echo "🛠️  Configurando Nginx para NS-SERVICES..."

cat > /etc/nginx/conf.d/ns-services.conf << 'EOF'
server {
    listen 10.10.0.10:80;
    server_name _;
    root /var/www/ns-services;
    index index.html;

    access_log /var/log/nginx/ns-services.access.log;
    error_log  /var/log/nginx/ns-services.error.log;
}
EOF

# Validación de sintaxis
nginx -t >/dev/null

# ============================================================================
# [5/5] Lanzador de Servicios (Control del Lab)
# ============================================================================
cat > /usr/local/bin/lab-start-services << 'EOF'
#!/bin/bash

echo "🚀 Iniciando servicio Web en NS-SERVICES..."

# Verificación defensiva
ip netns list | grep -qw NS-SERVICES || {
  echo "❌ Namespace NS-SERVICES no existe"
  exit 1
}

# Arranque del servicio dentro del namespace
ip netns exec NS-SERVICES nginx -g "daemon off;" &

sleep 1

# Verificación local (desde el propio namespace)
ip netns exec NS-SERVICES ss -lnt | grep -q ":80" \
  && echo "✅ Nginx escuchando correctamente en 10.10.0.10:80" \
  || echo "⚠️  Nginx no está escuchando como se esperaba"
EOF

chmod +x /usr/local/bin/lab-start-services

# ============================================================================
# Finalización
# ============================================================================
echo "===================================================="
echo "🏆 CAPA WEB DESPLEGADA Y ALINEADA"
echo
echo "▶ Iniciar servicio:"
echo "   lab-start-services"
echo
echo "▶ Pruebas recomendadas:"
echo "   China:     ip netns exec NS-CLIENT curl http://10.10.0.10"
echo "   SysAdmin: ip netns exec NS-SYSADMIN curl http://10.10.0.10"
echo
echo "▶ Debugging:"
echo "   ip netns exec NS-SERVICES ss -lntp"
echo "   tail -f /var/log/nginx/ns-services.access.log"
echo "===================================================="
