# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   3 de 5 – Aprovisionamiento de Lógica y Datos (Application Layer)
# ============================================================================
#
# OBJETIVO DE ESTE SCRIPT:
#   Preparar la capa lógica del laboratorio una vez que la infraestructura
#   de red (Bridge Layer) ya está operativa y persistente.
#
# ESTE SCRIPT SE ENCARGA DE:
#   1) Endurecer y configurar MariaDB en el Host (VM raíz).
#   2) Crear y mantener una base de datos de estado del laboratorio (labdb).
#   3) Generar un Config-Store centralizado para los servicios:
#        - Nginx
#        - Dnsmasq
#   4) Desplegar contenido web de diagnóstico reutilizable.
#
# DISEÑO:
#   - Este script es IDEMPOTENTE.
#   - Puede ejecutarse múltiples veces sin generar estados inconsistentes.
#   - Está pensado para ejecutarse después de snapshots.
#
# ---------------------------------------------------------------------------
# VALIDACIONES OBLIGATORIAS PREVIAS (SCRIPT 2 – BRIDGE LAYER)
#
# Antes de ejecutar este Script 3, el operador DEBE confirmar que el Script 2
# se ejecutó correctamente y que la red está funcional.
#
# VALIDACIONES RECOMENDADAS:
#
# 1) Verificar que el Bridge central existe y tiene la IP correcta:
#    ip addr show br-lab
#    → Debe mostrar: 10.10.100.1/24
#
# 2) Verificar que el servicio de persistencia de red está activo:
#    systemctl status lab-network.service
#    → Estado esperado: active (exited)
#
# 3) Verificar que los namespaces existen:
#    ip netns list
#    → Deben existir: NS-SERVICES y NS-CLIENT
#
# 4) Verificar conectividad desde NS-SERVICES hacia el Host (Gateway):
#    ip netns exec NS-SERVICES ping -c 2 10.10.100.1
#    → Debe responder
#
# 5) Verificar conectividad Cliente → Servicios:
#    ip netns exec NS-CLIENT ping -c 2 10.10.100.10
#    → Debe responder
#
# 6) Validación rápida usando la herramienta del Script 2:
#    lab-network-status
#    → Todos los checks deben mostrar OK
#
# SI ALGUNA VALIDACIÓN FALLA:
#   ❌ NO ejecutar este Script 3
#   ✔️ Revisar y corregir el Script 2
#
# ---------------------------------------------------------------------------
# DEPENDENCIAS:
#   - Script 1 ejecutado correctamente.
#   - Script 2 ejecutado y persistido vía systemd.
#
# PRÓXIMO PASO:
#   - Script 4: Ejecución real de Nginx y Dnsmasq dentro de NS-SERVICES,
#     utilizando las configuraciones generadas aquí.
# ============================================================================



set -e

echo "=== 🖥️  SCRIPT 3: PROVISIÓN DE CONFIGURACIONES (MODO BRIDGE) ==="
echo "📅 Fecha: $(date)"

# ---------------------------------------------------------------------------
# 1. VERIFICACIÓN DE INTEGRIDAD DE RED (SCRIPT 2)
# ---------------------------------------------------------------------------
echo "[1/4] 🔍 Verificando infraestructura de red..."
if ! ip addr show br-lab > /dev/null 2>&1; then
    echo "❌ ERROR CRÍTICO: El bridge 'br-lab' no existe. Ejecute el Script 2."
    exit 1
fi
echo "   ✅ Bridge br-lab presente."

# ---------------------------------------------------------------------------
# 2. MARIADB – HARDENING + DATA SEEDING (HOST LAYER)
# ---------------------------------------------------------------------------
echo "[2/4] 🗄️  Configurando MariaDB (Host)..."

systemctl enable --now mariadb

# Hardening básico + creación de DB y usuario
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'redhat';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;

CREATE DATABASE IF NOT EXISTS labdb;
CREATE USER IF NOT EXISTS 'labuser'@'%' IDENTIFIED BY 'redhat';
GRANT ALL PRIVILEGES ON labdb.* TO 'labuser'@'%';
FLUSH PRIVILEGES;
EOF

# Tabla de estado (IDEMPOTENTE)
mysql -u root -predhat labdb <<EOF
CREATE TABLE IF NOT EXISTS system_status (
    id INT AUTO_INCREMENT PRIMARY KEY,
    component VARCHAR(50) UNIQUE,
    status VARCHAR(20),
    last_check TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO system_status (component, status)
VALUES
    ('Database', 'Operational'),
    ('Bridge-Network', 'Active')
ON DUPLICATE KEY UPDATE
    status = VALUES(status),
    last_check = CURRENT_TIMESTAMP;
EOF

# Asegurar escucha en todas las interfaces (Bridge incluido)
sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' \
    /etc/my.cnf.d/mariadb-server.cnf 2>/dev/null || true

systemctl restart mariadb
echo "   ✅ MariaDB endurecida y accesible desde el Bridge."

# ---------------------------------------------------------------------------
# 3. CONFIG-STORE CENTRALIZADO (PARA NAMESPACES)
# ---------------------------------------------------------------------------
echo "[3/4] ⚙️  Generando Config-Store..."

mkdir -p /etc/lab-configs

# NGINX – Namespace NS-SERVICES
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

# DNSMASQ – Namespace NS-SERVICES
cat > /etc/lab-configs/dnsmasq.conf << 'EOF'
interface=veth-srv
listen-address=10.10.100.10
bind-interfaces

# Resolución interna del Lab
address=/web.lab.local/10.10.100.10
address=/db.lab.local/10.10.100.1

# Forwarders externos
server=8.8.8.8
EOF

echo "   ✅ Configuraciones listas en /etc/lab-configs."

# ---------------------------------------------------------------------------
# 4. DESPLIEGUE DE CONTENIDO WEB (HOST)
# ---------------------------------------------------------------------------
echo "[4/4] 📄 Desplegando portal de diagnóstico..."

mkdir -p /usr/share/nginx/html

cat > /usr/share/nginx/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Golden Base Lab - Bridge Mode</title>
</head>
<body style="font-family: sans-serif; text-align: center; background-color: #f4f4f4; padding-top: 50px;">
    <div style="background: white; display: inline-block; padding: 20px;
                border-radius: 10px; border: 1px solid #ccc;">
        <h1>Lab Bridge Operativo</h1>
        <p>Servicio Nginx ejecutándose en <b>NS-SERVICES</b>.</p>
        <p>MariaDB accesible en el Host (<b>10.10.100.1</b>).</p>
        <hr>
        <small>Golden Image – Arquitectura 3-Tier (2026)</small>
    </div>
</body>
</html>
EOF

# ---------------------------------------------------------------------------
# FINAL
# ---------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "✅ SCRIPT 3 COMPLETADO CORRECTAMENTE"
echo "=========================================="
echo ""
echo "📌 Estado:"
echo "   • MariaDB: Endurecida + DB labdb operativa"
echo "   • Config-Store: /etc/lab-configs"
echo "   • Portal Web: Preparado"
echo ""
echo "➡️  Próximo paso: SCRIPT 4 (Servicios reales en NS-SERVICES)"
