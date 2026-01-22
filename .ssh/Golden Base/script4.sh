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

#!/bin/bash
set -e

echo "=== 🚀 SCRIPT 4: ORQUESTACIÓN EN MODO BRIDGE (AUTO-FIX) ==="
echo "📅 Fecha: $(date)"

# ---------------------------------------------------------------------------
# 1. VALIDACIÓN Y PREPARACIÓN DEL RUNTIME
# ---------------------------------------------------------------------------
echo "[1/4] 🔍 Preparando entorno de ejecución..."

for f in /etc/lab-configs/nginx.conf /etc/lab-configs/dnsmasq.conf; do
    [[ -f "$f" ]] || { echo "❌ ERROR: Falta archivo de configuración $f"; exit 1; }
done

# Corregir el error de "Conexión rechazada" asegurando el directorio del PID
# Esto resuelve el problema de Nginx que detectaste manualmente.
mkdir -p /run/nginx
chown -R nginx:nginx /run/nginx
chmod 755 /run/nginx

echo "   ✅ Runtime y permisos configurados."

# ---------------------------------------------------------------------------
# 2. UNIDAD SYSTEMD: NGINX EN NS-SERVICES
# ---------------------------------------------------------------------------
echo "[2/4] 🌐 Configurando servicio Nginx en Namespace..."

cat > /etc/systemd/system/lab-nginx.service << 'EOF'
[Unit]
Description=Nginx Web Server (Aislado en NS-SERVICES)
After=lab-network.service
Wants=lab-network.service

[Service]
Type=simple
# Espera a que la interfaz y la IP estén listas dentro del namespace
ExecStartPre=/usr/sbin/ip netns exec NS-SERVICES /bin/bash -c \
'until ip addr show veth-srv | grep -q "10.10.100.10"; do sleep 1; done'

# Ejecución en primer plano para que systemd pueda monitorear el proceso
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
echo "[3/4] 📡 Configurando servicio Dnsmasq en Namespace..."

cat > /etc/systemd/system/lab-dnsmasq.service << 'EOF'
[Unit]
Description=Dnsmasq DNS Server (Aislado en NS-SERVICES)
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
# 4. ACTIVACIÓN Y AUTOMATIZACIÓN DE CLIENTE
# ---------------------------------------------------------------------------
echo "[4/4] 🔌 Activando servicios y configurando resolución..."

systemctl daemon-reload
systemctl enable lab-nginx.service lab-dnsmasq.service

# Reiniciar para aplicar cambios
systemctl restart lab-nginx.service
systemctl restart lab-dnsmasq.service

# --- SOLUCIÓN AUTOMÁTICA PARA EL CLIENTE ---
# Inyectamos el nameserver directamente en el namespace del cliente
# Esto reemplaza tu comando manual de 'echo' y evita usar nmcli.
echo "   💉 Configurando DNS en NS-CLIENT (10.10.100.10)..."
ip netns exec NS-CLIENT bash -c 'echo "nameserver 10.10.100.10" > /etc/resolv.conf'

sleep 2

echo ""
echo "===================================================="
echo "✅ FASE 4 COMPLETADA: ORQUESTACIÓN EXITOSA"
echo "===================================================="
echo "📊 ESTADO ACTUAL:"
echo "   • lab-nginx:   $(systemctl is-active lab-nginx)"
echo "   • lab-dnsmasq: $(systemctl is-active lab-dnsmasq)"
echo ""
echo "🧪 PRUEBA DE RESOLUCIÓN:"
ip netns exec NS-CLIENT curl -I http://web.lab.local
echo "===================================================="