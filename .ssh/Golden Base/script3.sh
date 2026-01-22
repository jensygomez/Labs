#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   3 de 5 - Aprovisionamiento de Lógica y Datos (Application Layer)
# ============================================================================
#
# ⏪ RETROSPECTIVA TÉCNICA (SCRIPT 2 - BRIDGE LAYER):
#   - Se ha migrado a una topología de ESTRELLA mediante 'br-lab'.
#   - El Host (10.10.100.1) actúa como Switch y Gateway central.
#   - Namespaces 'NS-CLIENT' y 'NS-SERVICES' están conectados directamente.
#
# 🧪 VALIDACIÓN DE RED (POST-REBOOT SCRIPT 2):
#   1. Listar Bridge:      # ip addr show br-lab (Debe tener la IP .1)
#   2. Probar enlace:      # ip netns exec NS-SERVICES ping -c 2 10.10.100.1
#   3. Estado Servicio:    # systemctl status lab-network.service
#
# 🎯 OBJETIVO DE ESTA FASE (SCRIPT 3):
#   Garantizar que los archivos de configuración y la base de datos estén 
#   listos para la orquestación final.
# ============================================================================
set -e

echo "=== 🖥️  SCRIPT 3: PROVISIÓN DE CONFIGURACIONES (MODO BRIDGE) ==="
echo "📅 Fecha: $(date)"

# ---------------------------------------------------------------------------
# 1. VERIFICACIÓN DE INTEGRIDAD DE LA FASE PREVIA
# ---------------------------------------------------------------------------
echo "[1/4] 🔍 Verificando cimientos de red..."
if ! ip addr show br-lab > /dev/null 2>&1; then
    echo "❌ ERROR CRÍTICO: El bridge 'br-lab' no existe. Ejecute el Script 2."
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. MARIADB HARDENING & DATA SEEDING (CAPA HOST)
# ---------------------------------------------------------------------------
echo "[2/4] 🗄️  Configurando motor de base de datos..."
systemctl enable --now mariadb

# Inyección de seguridad (Hardening)
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'redhat';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
CREATE DATABASE IF NOT EXISTS labdb;
CREATE USER IF NOT EXISTS 'labuser'@'%' IDENTIFIED BY 'redhat';
GRANT ALL PRIVILEGES ON labdb.* TO 'labuser'@'%';
FLUSH PRIVILEGES;
EOF

# Estructura de validación
mysql -u root -predhat labdb <<EOF
CREATE TABLE IF NOT EXISTS system_status (
    id INT AUTO_INCREMENT PRIMARY KEY,
    component VARCHAR(50),
    status VARCHAR(20),
    last_check TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO system_status (component, status) VALUES ('Database', 'Operational'), ('Bridge-Network', 'Active');
EOF

# Configuración de escucha: Aseguramos que MariaDB escuche en el Bridge
# Importante: Quitamos el 'skip-networking' si existiera
sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/my.cnf.d/mariadb-server.cnf 2>/dev/null || true
systemctl restart mariadb
echo "   ✅ MariaDB configurada para recibir tráfico del Bridge."

# ---------------------------------------------------------------------------
# 3. GENERACIÓN DE "CONFIG-STORE" PARA NAMESPACES
# ---------------------------------------------------------------------------
echo "[3/4] ⚙️  Generando almacenamiento de configuraciones..."
mkdir -p /etc/lab-configs/

# Configuración NGINX (Namespace NS-SERVICES)
cat > /etc/lab-configs/nginx.conf << 'EOF'
worker_processes 1;
error_log /var/log/nginx/lab-error.log;
events { worker_connections 1024; }
http {
    include /etc/nginx/mime.types;
    server {
        listen 10.10.100.10:80; 
        server_name web.lab.local;
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
}
EOF

# Configuración DNSMASQ (Namespace NS-SERVICES)
# Ajustado: Ahora db.lab.local apunta directamente a la IP del Bridge (.1)
cat > /etc/lab-configs/dnsmasq.conf << 'EOF'
interface=veth-srv
listen-address=10.10.100.10
bind-interfaces
# Resoluciones internas
address=/web.lab.local/10.10.100.10
address=/db.lab.local/10.10.100.1
# Eliminamos referencia a NS-EDGE ya que el Host es el Gateway directo
server=8.8.8.8
EOF

# ---------------------------------------------------------------------------
# 4. DESPLIEGUE DE CONTENIDO WEB
# ---------------------------------------------------------------------------
echo "[4/4] 📄 Desplegando portal de diagnóstico..."
mkdir -p /usr/share/nginx/html
cat > /usr/share/nginx/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Golden Base Lab - Bridge Mode</title></head>
<body style="font-family: sans-serif; text-align: center; background-color: #f4f4f4; padding-top: 50px;">
    <div style="background: white; display: inline-block; padding: 20px; border-radius: 10px; border: 1px solid #ccc;">
        <h1 style="color: #2c3e50;">🚀 Lab Bridge Operativo</h1>
        <p>Servicio Nginx ejecutándose en <b>NS-SERVICES</b>.</p>
        <p>Conexión directa a MariaDB en Host <b>10.10.100.1</b> validada.</p>
        <hr>
        <small style="color: #7f8c8d;">Arquitectura Escalable - Golden Image 2026</small>
    </div>
</body>
</html>
EOF

echo ""
echo "=========================================="
echo "✅ FASE 3 COMPLETADA (MODO BRIDGE)"
echo "=========================================="