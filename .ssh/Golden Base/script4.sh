#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   4 de 5 - Orquestación y Automatización (Orchestration Layer)
# ============================================================================
#
# ⏪ CONTEXTO TÉCNICO PREVIO (SCRIPT 2 y 3):
#
# SCRIPT 2 - NETWORK LAYER (BRIDGE MODE)
#   - Bridge br-lab creado con IP 10.10.100.1/24
#   - Namespace NS-SERVICES conectado vía veth-srv (10.10.100.10)
#   - Persistencia garantizada por systemd (lab-network.service)
#
#   COMANDOS DE VALIDACIÓN:
#     ip addr show br-lab
#     ip netns list
#     ip netns exec NS-SERVICES ip addr show veth-srv
#
# SCRIPT 3 - APPLICATION PREP
#   - MariaDB operativo en el Host (10.10.100.1:3306)
#   - Configuraciones centralizadas en /etc/lab-configs/
#       • nginx.conf  (bind explícito a 10.10.100.10:80)
#       • dnsmasq.conf
#
#   COMANDOS DE VALIDACIÓN:
#     systemctl status mariadb
#     ss -lntp | grep 3306
#     ls -l /etc/lab-configs/
#
# NOTA CRÍTICA APRENDIDA:
#   - Nginx ejecutado vía systemd + namespaces requiere:
#       • Directorio runtime explícito: /run/nginx
#       • PID definido manualmente en nginx.conf
#         pid /run/nginx/nginx.pid;
#
# 🎯 OBJETIVO DE ESTE SCRIPT (SCRIPT 4):
#   - Elevar Nginx y Dnsmasq como servicios systemd
#   - Ejecutarlos DENTRO del namespace NS-SERVICES
#   - Garantizar orden de arranque, persistencia y resiliencia
#
# RESULTADO ESPERADO:
#   - curl http://10.10.100.10  → HTTP 200
#   - Resolución DNS funcional desde NS-CLIENT
# ============================================================================

set -e

echo "=== 🚀 SCRIPT 4: ORQUESTACIÓN EN MODO BRIDGE ==="
echo "📅 Fecha: $(date)"

# ---------------------------------------------------------------------------
# 1. VALIDACIÓN DE ARTEFACTOS CRÍTICOS
# ---------------------------------------------------------------------------
echo "[1/4] 🔍 Validando precondiciones..."

for f in /etc/lab-configs/nginx.conf /etc/lab-configs/dnsmasq.conf; do
    [[ -f "$f" ]] || { echo "❌ Falta $f"; exit 1; }
done

# Runtime requerido por Nginx (systemd + daemon off)
mkdir -p /run/nginx
chown -R nginx:nginx /run/nginx

echo "   ✅ Configuraciones y runtime listos."

# ---------------------------------------------------------------------------
# 2. UNIDAD SYSTEMD: NGINX EN NS-SERVICES
# ---------------------------------------------------------------------------
echo "[2/4] 🌐 Definiendo servicio Nginx (namespace)..."

cat > /etc/systemd/system/lab-nginx.service << 'EOF'
[Unit]
Description=Nginx Web Server (Aislado en NS-SERVICES - Bridge Mode)
After=lab-network.service
Wants=lab-network.service

[Service]
Type=simple

# Espera activa hasta que la IP exista en el namespace
ExecStartPre=/usr/sbin/ip netns exec NS-SERVICES /bin/bash -c \
'until ip addr show veth-srv | grep -q "10.10.100.10"; do sleep 1; done'

# Ejecución explícita sin daemonización
ExecStart=/usr/sbin/ip netns exec NS-SERVICES \
/usr/sbin/nginx -c /etc/lab-configs/nginx.conf -g "daemon off;"

ExecStop=/usr/sbin/ip netns exec NS-SERVICES /usr/sbin/nginx -s stop

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ---------------------------------------------------------------------------
# 3. UNIDAD SYSTEMD: DNSMASQ EN NS-SERVICES
# ---------------------------------------------------------------------------
echo "[3/4] 📡 Definiendo servicio Dnsmasq (namespace)..."

cat > /etc/systemd/system/lab-dnsmasq.service << 'EOF'
[Unit]
Description=Dnsmasq DNS Server (Aislado en NS-SERVICES - Bridge Mode)
After=lab-network.service
Wants=lab-network.service

[Service]
Type=simple

ExecStart=/usr/sbin/ip netns exec NS-SERVICES \
/usr/sbin/dnsmasq -k -C /etc/lab-configs/dnsmasq.conf

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ---------------------------------------------------------------------------
# 4. ACTIVACIÓN Y VALIDACIÓN
# ---------------------------------------------------------------------------
echo "[4/4] 🔌 Activando servicios..."

systemctl daemon-reload
systemctl enable lab-nginx.service lab-dnsmasq.service

systemctl restart lab-nginx.service
systemctl restart lab-dnsmasq.service

sleep 2

echo ""
echo "===================================================="
echo "✅ FASE 4 COMPLETADA: ORQUESTACIÓN EXITOSA"
echo "===================================================="
echo "📊 ESTADO:"
echo "   • lab-nginx:   $(systemctl is-active lab-nginx)"
echo "   • lab-dnsmasq: $(systemctl is-active lab-dnsmasq)"
echo ""
echo "🧪 VALIDACIÓN MANUAL:"
echo "   ip netns exec NS-SERVICES ss -lntp | grep :80"
echo "   curl http://10.10.100.10"
echo "===================================================="
