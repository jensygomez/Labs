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
# 🧪 VALIDACIÓN DE PERSISTENCIA (POST-REBOOT SCRIPT 3):
#   Tras reiniciar, verifique que la capa de aplicación y datos está lista:
#   1. DB Activa:       # systemctl is-active mariadb
#   2. Datos en DB:     # mysql -u labuser -predhat -h localhost labdb -e "show tables;"
#   3. Configs Web:     # ls -l /etc/lab-configs/nginx.conf
#   4. Configs DNS:     # ls -l /etc/lab-configs/dnsmasq.conf
#   5. HTML Root:       # ls -l /usr/share/nginx/html/index.html
#
# 🎯 OBJETIVO DE ESTA FASE (SCRIPT 4):
#   Dar vida a los servicios. Este script crea las "Unidades de Servicio" 
#   de Systemd que encapsulan procesos de usuario dentro de Namespaces 
#   de Red. Es el puente final entre el software y la topología virtual.
#
# 🛠️ MECANISMOS DE INGENIERÍA IMPLEMENTADOS:
#   1. ENCAPSULAMIENTO EXECUTOR: Se utiliza 'ip netns exec' como wrapper 
#      principal utilizando rutas absolutas de binarios (/usr/sbin/ip).
#   2. GESTIÓN DE PROCESOS (Type=simple): Se configuran los servicios para 
#      ejecutarse en primer plano (daemon off) permitiendo que Systemd 
#      monitoree el ciclo de vida real del proceso dentro del namespace.
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
#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   4 de 5 - Orquestación y Automatización (Orchestration Layer) - CORREGIDO
# ============================================================================
set -e

echo "=== 🚀 SCRIPT 4: ORQUESTACIÓN DE SERVICIOS EN NAMESPACES (VERSIÓN FINAL) ==="
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
# 2. CREACIÓN DE LA UNIDAD: NGINX-NAMESPACE (CORREGIDO)
# ---------------------------------------------------------------------------
echo "[2/4] 🌐 Orquestando Nginx para NS-SERVICES..."

cat > /etc/systemd/system/lab-nginx.service << 'EOF'
[Unit]
Description=Nginx Web Server (Aislado en NS-SERVICES)
After=lab-network.service
Wants=lab-network.service
PartOf=lab-network.service

[Service]
# Se usa Type=simple para evitar bloqueos con ip netns exec
Type=simple
# Se especifica la ruta completa /usr/sbin/ip detectada con which
# Se añade 'daemon off' para que el proceso no se pierda de la vista de Systemd
ExecStart=/usr/sbin/ip netns exec NS-SERVICES /usr/sbin/nginx -c /etc/lab-configs/nginx.conf -g "daemon off;"
ExecStop=/usr/sbin/ip netns exec NS-SERVICES /usr/sbin/nginx -s stop
ExecReload=/usr/sbin/ip netns exec NS-SERVICES /usr/sbin/nginx -s reload

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ---------------------------------------------------------------------------
# 3. CREACIÓN DE LA UNIDAD: DNSMASQ-NAMESPACE (CORREGIDO)
# ---------------------------------------------------------------------------
echo "[3/4] 📡 Orquestando Dnsmasq para NS-SERVICES..."

cat > /etc/systemd/system/lab-dnsmasq.service << 'EOF'
[Unit]
Description=Dnsmasq DNS Server (Aislado en NS-SERVICES)
After=lab-network.service

[Service]
Type=simple
# Se usa la ruta /usr/sbin/ip y el flag -k (keep-in-foreground)
ExecStart=/usr/sbin/ip netns exec NS-SERVICES /usr/sbin/dnsmasq -k -C /etc/lab-configs/dnsmasq.conf

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ---------------------------------------------------------------------------
# 4. DISPARO DE SERVICIOS Y SINCRONIZACIÓN
# ---------------------------------------------------------------------------
echo "[4/4] 🔌 Activando orquestación y cargando unidades..."

# Recargar el daemon para registrar los cambios
systemctl daemon-reload

# Habilitar persistencia
systemctl enable lab-nginx.service
systemctl enable lab-dnsmasq.service

# Iniciar servicios
echo "   ➡️ Iniciando Nginx y Dnsmasq en Namespaces..."
systemctl restart lab-nginx.service
systemctl restart lab-dnsmasq.service

# Pequeña espera para estabilización
sleep 2

echo ""
echo "===================================================="
echo "✅ FASE 4 COMPLETADA: SERVICIOS ORQUESTADOS"
echo "===================================================="
echo "📊 ESTADO DE LOS PROCESOS:"
echo "   • lab-nginx:   $(systemctl is-active lab-nginx)"
echo "   • lab-dnsmasq: $(systemctl is-active lab-dnsmasq)"
echo ""
echo "🚀 PRÓXIMO PASO: Script 5 (Validación Final y Hardening)"
echo "===================================================="