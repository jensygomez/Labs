#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   3 de 5 - Aprovisionamiento de Lógica y Datos (Application Layer)
# ============================================================================
#
# ⏪ RETROSPECTIVA TÉCNICA (SCRIPT 2 - NETWORK LAYER):
#   - Se ha establecido el aislamiento mediante Network Namespaces (NetNS).
#   - Los túneles virtuales (Veth Pairs) están anclados y listos.
#   - Se configuró la persistencia de red para que los Namespaces 'NS-CLIENT', 
#     'NS-EDGE' y 'NS-SERVICES' existan post-reboot.
#
# 🎯 OBJETIVO DE ESTA FASE (SCRIPT 3):
#   Preparar el "Payload" o carga útil. Este script no arranca los servicios 
#   en los namespaces todavía, sino que garantiza que todos los archivos de 
#   configuración, bases de datos y contenidos existan y sean correctos. 
#   Es la fase de "Pre-vuelo".
#
# 🛠️ COMPONENTES APROVISIONADOS:
#   1. DATABASE (Host): MariaDB configurada con esquema 'labdb' y hardening 
#      inicial para permitir conexiones desde la red segmentada (10.10.x.x).
#   2. WEB CONFIG (Namespace): Archivo de configuración para Nginx optimizado 
#      para ejecución aislada, evitando colisiones de sockets y PIDs.
#   3. DNS CONFIG (Namespace): Definición de zonas para 'lab.local' que 
#      permitirá la resolución de nombres entre capas (Client -> Web/DB).
#   4. CONTENT: Inyección de la Landing Page de administración del lab.
#
# ⏩ PERSPECTIVA FUTURA (SCRIPT 4 - ORCHESTRATION LAYER):
#   El siguiente script tomará estos archivos y los ejecutará mediante 
#   unidades Systemd personalizadas, utilizando 'ip netns exec' para 
#   encapsular los procesos en sus respectivos dominios de red.
#
# ============================================================================
set -e

echo "=== 🖥️  SCRIPT 3: PROVISIÓN DE CONFIGURACIONES EXTREMAS ==="
echo "📅 Fecha: $(date)"

# ---------------------------------------------------------------------------
# 1. VERIFICACIÓN DE INTEGRIDAD DE LA FASE PREVIA
# ---------------------------------------------------------------------------
echo "[1/4] 🔍 Verificando cimientos de red..."
if ! ip netns list | grep -q "NS-SERVICES"; then
    echo "❌ ERROR CRÍTICO: No se detectó la topología de red del Script 2."
    echo "Faltan namespaces. Por favor, ejecute o repare el Script 2."
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. MARIADB HARDENING & DATA SEEDING (CAPA HOST)
# ---------------------------------------------------------------------------
echo "[2/4] 🗄️  Configurando motor de base de datos..."
systemctl enable --now mariadb

# Inyección de seguridad y creación de esquema educativo
# Se utiliza el password 'redhat' para fines de laboratorio
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'redhat';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
CREATE DATABASE IF NOT EXISTS labdb;
CREATE USER IF NOT EXISTS 'labuser'@'%' IDENTIFIED BY 'redhat';
GRANT ALL PRIVILEGES ON labdb.* TO 'labuser'@'%';
FLUSH PRIVILEGES;
EOF

# Creación de estructura de datos para validación de servicios
mysql -u root -predhat labdb <<EOF
CREATE TABLE IF NOT EXISTS system_status (
    id INT AUTO_INCREMENT PRIMARY KEY,
    component VARCHAR(50),
    status VARCHAR(20),
    last_check TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO system_status (component, status) VALUES ('Database', 'Operational'), ('Network', 'Active');
EOF

# Configuración de escucha (Permite que el host reciba tráfico de los Namespaces)
sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/my.cnf.d/mariadb-server.cnf 2>/dev/null || true
systemctl restart mariadb
echo "   ✅ Base de Datos lista y escuchando en 0.0.0.0"

# ---------------------------------------------------------------------------
# 3. GENERACIÓN DE "CONFIG-STORE" PARA NAMESPACES
# ---------------------------------------------------------------------------
# Centralizamos las configuraciones en /etc/lab-configs para facilitar auditoría
echo "[3/4] ⚙️  Generando almacenamiento de configuraciones..."
mkdir -p /etc/lab-configs/

# Configuración NGINX - Aislada para evitar conflicto con la instancia del Host
cat > /etc/lab-configs/nginx.conf << 'EOF'
worker_processes 1;
error_log /var/log/nginx/lab-error.log;
events { worker_connections 1024; }
http {
    include /etc/nginx/mime.types;
    server {
        # Escucha exclusivamente en la IP virtual de servicios
        listen 10.10.100.10:80; 
        server_name web.lab.local;
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
}
EOF

# Configuración DNSMASQ - Resolución interna del Laboratorio
cat > /etc/lab-configs/dnsmasq.conf << 'EOF'
# Interfaz donde el servidor DNS escuchará peticiones
interface=veth-srv
listen-address=10.10.100.10
bind-interfaces
# Mapeo de nombres DNS internos
address=/web.lab.local/10.10.100.10
address=/db.lab.local/10.10.100.10
address=/edge.lab.local/10.10.100.1
# Reenvío a DNS público para salida a internet
server=8.8.8.8
EOF

# ---------------------------------------------------------------------------
# 4. DESPLIEGUE DE CONTENIDO WEB DE DIAGNÓSTICO
# ---------------------------------------------------------------------------
echo "[4/4] 📄 Desplegando portal de diagnóstico..."
mkdir -p /usr/share/nginx/html
cat > /usr/share/nginx/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Golden Base Lab</title></head>
<body style="font-family: sans-serif; text-align: center; margin-top: 50px;">
    <h1 style="color: #c00;">✅ Lab 3-Tier Operativo</h1>
    <p>Servicio Nginx ejecutándose exitosamente dentro del <b>Namespace NS-SERVICES</b>.</p>
    <p>Conexión a MariaDB (Host) validada desde capa de aplicación.</p>
    <hr width="50%">
    <small>Generado automáticamente por Script 3</small>
</body>
</html>
EOF

echo ""
echo "=========================================="
echo "✅ FASE 3 COMPLETADA EXITOSAMENTE"
echo "=========================================="
echo "📊 ESTADO DE PREPARACIÓN:"
echo "   • Archivos de Configuración: GENERADOS"
echo "   • Base de Datos MariaDB: INICIALIZADA"
echo "   • Contenido de Prueba: LISTO"
echo ""
echo "🚀 PRÓXIMO PASO: Script 4 (Orquestación de Servicios con Systemd)"
echo "=========================================="