#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   4 de 5 - Orquestación y Automatización (Orchestration Layer)
# ============================================================================
#
# ⏪ RETROSPECTIVA TÉCNICA (SCRIPT 3 - APP LAYER):
#   - Se han generado los archivos de configuración en /etc/lab-configs/.
#   - La base de datos MariaDB está inicializada y con privilegios remotos.
#   - El contenido web de diagnóstico está desplegado en disco.
#
# 🎯 OBJETIVO DE ESTA FASE (SCRIPT 4):
#   Dar vida a los servicios. Este script crea las "Unidades de Servicio" 
#   de Systemd que encapsulan procesos de usuario dentro de Namespaces 
#   de Red. Es el puente final entre el software y la topología virtual.
#
# 🛠️ MECANISMOS DE INGENIERÍA IMPLEMENTADOS:
#   1. ENCAPSULAMIENTO EXECUTOR: Se utiliza 'ip netns exec' como wrapper 
#      principal para los binarios de Nginx y Dnsmasq.
#   2. GESTIÓN DE PIDs INDEPENDIENTE: Se redirigen los archivos de control 
#      (.pid) a rutas personalizadas para evitar conflictos con el host.
#   3. CADENA DE DEPENDENCIAS: Se configuran las unidades para que esperen 
#      obligatoriamente a 'lab-network.service' (Script 2).
#   4. AUTO-SANACIÓN (Self-Healing): Reinicio automático en caso de fallo 
#      del proceso dentro del namespace.
#
# ⏩ PERSPECTIVA FUTURA (SCRIPT 5 - AUDIT LAYER):
#   El último script realizará las pruebas de estrés, validación de 
#   conectividad extremo a extremo y el sellado de la Golden Image.
#
# ============================================================================
set -e

echo "=== 🚀 SCRIPT 4: ORQUESTACIÓN DE SERVICIOS EN NAMESPACES ==="
echo "📅 Fecha: $(date)"

# ---------------------------------------------------------------------------
# 1. VALIDACIÓN DE RECURSOS PREVIOS
# ---------------------------------------------------------------------------
echo "[1/4] 🔍 Validando existencia de configuraciones..."
if [[ ! -f /etc/lab-configs/nginx.conf ]] || [[ ! -f /etc/lab-configs/dnsmasq.conf ]]; then
    echo "❌ ERROR CRÍTICO: No se encontraron los archivos de configuración del Script 3."
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. CREACIÓN DE LA UNIDAD: NGINX-NAMESPACE
# ---------------------------------------------------------------------------
# Este servicio lanza Nginx dentro de NS-SERVICES. 
# Se usa 'forking' porque Nginx genera procesos hijos.
echo "[2/4] 🌐 Orquestando Nginx para NS-SERVICES..."

cat > /etc/systemd/system/lab-nginx.service << 'EOF'
[Unit]
Description=Nginx Web Server (Aislado en NS-SERVICES)
After=lab-network.service
Wants=lab-network.service
PartOf=lab-network.service

[Service]
Type=forking
# Definimos una ruta de PID única para el namespace
PIDFile=/run/nginx-ns-services.pid

# Pre-ejecución: Asegurar que el directorio de runtime existe
ExecStartPre=/usr/bin/mkdir -p /run/nginx

# Ejecución: Wrapper ip netns exec + comando nginx con PID personalizado
ExecStart=/usr/bin/ip netns exec NS-SERVICES /usr/sbin/nginx -c /etc/lab-configs/nginx.conf -g "pid /run/nginx-ns-services.pid;"
ExecStop=/usr/bin/ip netns exec NS-SERVICES /usr/sbin/nginx -s stop
ExecReload=/usr/bin/ip netns exec NS-SERVICES /usr/sbin/nginx -s reload

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ---------------------------------------------------------------------------
# 3. CREACIÓN DE LA UNIDAD: DNSMASQ-NAMESPACE
# ---------------------------------------------------------------------------
# Dnsmasq provee resolución DNS interna para que el CLIENTE encuentre a la WEB.
echo "[3/4] 📡 Orquestando Dnsmasq para NS-SERVICES..."

cat > /etc/systemd/system/lab-dnsmasq.service << 'EOF'
[Unit]
Description=Dnsmasq DNS Server (Aislado en NS-SERVICES)
After=lab-network.service lab-nginx.service

[Service]
Type=simple
# Ejecución: Modo keep-in-foreground para que Systemd pueda monitorearlo fácilmente
ExecStart=/usr/bin/ip netns exec NS-SERVICES /usr/sbin/dnsmasq -k -C /etc/lab-configs/dnsmasq.conf

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ---------------------------------------------------------------------------
# 4. DISPARO DE SERVICIOS Y SINCRONIZACIÓN
# ---------------------------------------------------------------------------
echo "[4/4] 🔌 Activando orquestación y cargando unidades..."

# Recargar el daemon de systemd para reconocer las nuevas unidades
systemctl daemon-reload

# Habilitar para que inicien en el próximo arranque (Persistencia)
systemctl enable lab-nginx.service
systemctl enable lab-dnsmasq.service

# Iniciar los servicios en orden
echo "   ➡️ Iniciando Nginx en Namespace..."
systemctl start lab-nginx.service
sleep 2

echo "   ➡️ Iniciando DNS en Namespace..."
systemctl start lab-dnsmasq.service
sleep 1

# ---------------------------------------------------------------------------
# RESUMEN DE OPERACIÓN
# ---------------------------------------------------------------------------
echo ""
echo "===================================================="
echo "✅ FASE 4 COMPLETADA: SERVICIOS ORQUESTADOS"
echo "===================================================="
echo "📊 ESTADO DE LOS PROCESOS:"
echo "   • lab-nginx:   $(systemctl is-active lab-nginx)"
echo "   • lab-dnsmasq: $(systemctl is-active lab-dnsmasq)"
echo ""
echo "⚙️  VERIFICACIÓN TÉCNICA DE AISLAMIENTO:"
echo "   PIDs detectados en NS-SERVICES:"
ip netns exec NS-SERVICES ps aux | grep -E 'nginx|dnsmasq' | grep -v grep
echo ""
echo "🚀 PRÓXIMO PASO: Script 5 (Validación Final y Hardening)"
echo "===================================================="