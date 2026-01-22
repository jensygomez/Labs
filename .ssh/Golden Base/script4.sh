#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   4 de 5 - Orquestación y Automatización (Orchestration Layer)
# ============================================================================
#
# ⏪ RETROSPECTIVA TÉCNICA (SCRIPT 3 - APP LAYER):
#   - Configuraciones generadas en /etc/lab-configs/ bajo modelo Bridge.
#   - MariaDB lista en el Host, escuchando peticiones desde 10.10.100.1.
#
# 🧪 VALIDACIÓN DE RED (POST-REBOOT SCRIPT 2 & 3):
#   1. Bridge Activo:   # ip addr show br-lab (IP 10.10.100.1)
#   2. DB Accesible:    # nc -zv 10.10.100.1 3306
#   3. Configs Listas:  # ls /etc/lab-configs/nginx.conf
#
# 🎯 OBJETIVO DE ESTA FASE (SCRIPT 4):
#   Elevar los servicios Nginx y Dnsmasq como unidades de Systemd que
#   viven dentro del Namespace 'NS-SERVICES', conectadas al Switch Virtual.
# ============================================================================
set -e

echo "=== 🚀 SCRIPT 4: ORQUESTACIÓN EN MODO BRIDGE ==="
echo "📅 Fecha: $(date)"

# ---------------------------------------------------------------------------
# 1. VALIDACIÓN DE RECURSOS PREVIOS
# ---------------------------------------------------------------------------
echo "[1/4] 🔍 Validando cimientos..."
if [[ ! -f /etc/lab-configs/nginx.conf ]] || [[ ! -f /etc/lab-configs/dnsmasq.conf ]]; then
    echo "❌ ERROR: Faltan archivos de configuración en /etc/lab-configs/."
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. CREACIÓN DE LA UNIDAD: NGINX-NAMESPACE
# ---------------------------------------------------------------------------
echo "[2/4] 🌐 Orquestando Nginx para NS-SERVICES..."

cat > /etc/systemd/system/lab-nginx.service << 'EOF'
[Unit]
Description=Nginx Web Server (Aislado en NS-SERVICES - Bridge Mode)
After=lab-network.service
Wants=lab-network.service

[Service]
Type=simple
# Ejecución dentro del namespace usando rutas absolutas
ExecStart=/usr/sbin/ip netns exec NS-SERVICES /usr/sbin/nginx -c /etc/lab-configs/nginx.conf -g "daemon off;"
ExecStop=/usr/sbin/ip netns exec NS-SERVICES /usr/sbin/nginx -s stop
# Reinicio automático si el proceso muere
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ---------------------------------------------------------------------------
# 3. CREACIÓN DE LA UNIDAD: DNSMASQ-NAMESPACE
# ---------------------------------------------------------------------------
echo "[3/4] 📡 Orquestando Dnsmasq para NS-SERVICES..."

cat > /etc/systemd/system/lab-dnsmasq.service << 'EOF'
[Unit]
Description=Dnsmasq DNS Server (Aislado en NS-SERVICES - Bridge Mode)
After=lab-network.service
Wants=lab-network.service

[Service]
Type=simple
# Flag -k para mantener el proceso en primer plano para Systemd
ExecStart=/usr/sbin/ip netns exec NS-SERVICES /usr/sbin/dnsmasq -k -C /etc/lab-configs/dnsmasq.conf
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ---------------------------------------------------------------------------
# 4. DISPARO DE SERVICIOS Y SINCRONIZACIÓN
# ---------------------------------------------------------------------------
echo "[4/4] 🔌 Activando orquestación..."

systemctl daemon-reload

# Habilitar para que inicien en el próximo arranque de la Golden Image
systemctl enable lab-nginx.service
systemctl enable lab-dnsmasq.service

# Iniciar ahora mismo para validar
echo "   ➡️ Iniciando servicios dentro de los namespaces..."
systemctl restart lab-nginx.service
systemctl restart lab-dnsmasq.service

# Espera técnica para que los sockets abran
sleep 2

echo ""
echo "===================================================="
echo "✅ FASE 4 COMPLETADA: SERVICIOS ORQUESTADOS"
echo "===================================================="
echo "📊 ESTADO ACTUAL:"
echo "   • lab-nginx:   $(systemctl is-active lab-nginx)"
echo "   • lab-dnsmasq: $(systemctl is-active lab-dnsmasq)"
echo ""
echo "📝 NOTA: Ahora puedes probar desde el Host:"
echo "   curl -I http://10.10.100.10"
echo "===================================================="