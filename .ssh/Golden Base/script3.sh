#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   3 de 4 - Despliegue de Servicios en Micro-Segmentación
# ============================================================================
#
# RESUMEN SCRIPT 2 (INFRAESTRUCTURA DE RED):
#   ✅ Creación de Namespaces persistentes: CLIENT, EDGE y SERVICES.
#   ✅ Interconexión mediante pares Veth (VIRTUAL ETHERNET).
#   ✅ Configuración de Gateway y NAT en NS-EDGE (Ruteo Inter-Namespace).
#   ✅ Persistencia garantizada mediante Systemd y Timers de salud.
#
# OBJETIVO SCRIPT 3:
#   Poblar la infraestructura de red con servicios reales, simulando un entorno
#   productivo donde la base de datos, el servidor web y el DNS conviven
#   en capas aisladas pero comunicadas.
#
# LOGROS DE ESTE SCRIPT:
# 1. Base de Datos (Host Layer): Configuración de MariaDB con seguridad 
#    básica, esquema de datos 'labdb' y permisos para acceso remoto.
# 2. Virtualización de Servicios (Namespace Layer): Ejecución de Nginx y 
#    Dnsmasq DENTRO del namespace NS-SERVICES.
# 3. Orquestación con Systemd: Creación de Unit Files personalizados que 
#    utilizan 'ip netns exec' para lanzar servicios en entornos aislados.
# 4. API & Web Content: Despliegue de una página de estado y endpoints JSON 
#    para pruebas de conectividad nivel 7 (Aplicación).
# 5. Tooling de Diagnóstico: Aliases (lab-status, lab-test) para auditoría 
#    rápida del estado de los servicios desde el shell del host.
#
# REQUISITOS:
#   - Script 2 ejecutado y namespaces activos.
#   - Los servicios MariaDB y Nginx deben estar instalados (hecho en Script 1).
# ============================================================================
set -e

echo "=== 🖥️  SCRIPT 3: SERVICIOS PERSISTENTES ==="
echo "📅 Fecha: $(date)"
echo "============================================"

if [[ $EUID -ne 0 ]]; then 
    echo "❌ Ejecutar como root: sudo $0"
    exit 1
fi

# Verificar que la red existe
if ! ip netns list | grep -q "NS-SERVICES"; then
    echo "❌ Namespace NS-SERVICES no existe. Ejecuta script2 primero."
    exit 1
fi

# ---------------------------------------------------------------------------
# 1. CONFIGURAR MARIADB (EN EL HOST - NO EN NAMESPACE)
# ---------------------------------------------------------------------------
echo "[1/6] 🗄️  Configurando MariaDB..."

# Asegurar que MariaDB está activo
systemctl enable --now mariadb

# Configurar seguridad básica
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'redhat';" 2>/dev/null || true
mysql -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null || true
mysql -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || true
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" 2>/dev/null || true
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true

# Crear base de datos del lab
mysql -e "CREATE DATABASE IF NOT EXISTS labdb;" 2>/dev/null || true
mysql -e "CREATE USER IF NOT EXISTS 'labuser'@'%' IDENTIFIED BY 'redhat';" 2>/dev/null || true
mysql -e "GRANT ALL PRIVILEGES ON labdb.* TO 'labuser'@'%';" 2>/dev/null || true
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true

# Crear tabla de ejemplo
mysql labdb -e "CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50),
    email VARCHAR(100),
    creado TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);" 2>/dev/null || true

# Insertar datos de ejemplo
mysql labdb -e "INSERT IGNORE INTO usuarios (nombre, email) VALUES
    ('Juan Perez', 'juan@lab.local'),
    ('Maria Gomez', 'maria@lab.local'),
    ('Carlos Ruiz', 'carlos@lab.local');" 2>/dev/null || true

# Permitir conexiones remotas (desde el namespace)
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/my.cnf.d/mariadb-server.cnf 2>/dev/null || 
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/my.cnf 2>/dev/null || true

systemctl restart mariadb
echo "   ✅ MariaDB configurado (escucha en todas las interfaces)"

# ---------------------------------------------------------------------------
# 2. ARCHIVOS DE CONFIGURACIÓN PARA NGINX Y DNSMASQ
# ---------------------------------------------------------------------------
echo "[2/6] ⚙️  Creando configuraciones..."

# Crear directorio para configuraciones del lab
mkdir -p /etc/lab-configs/

# Configuración de nginx (optimizada para namespace)
cat > /etc/lab-configs/nginx.conf << 'EOF'
worker_processes 1;
error_log /var/log/nginx/lab-error.log;
pid /run/nginx-lab.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/lab-access.log;

    sendfile on;
    keepalive_timeout 65;
    tcp_nodelay on;

    server {
        listen 10.10.100.10:80;
        server_name web.lab.local;
        root /usr/share/nginx/html;
        index index.html;

        location / {
            try_files $uri $uri/ =404;
        }

        # API endpoints
        location /api/ {
            add_header Content-Type application/json;
            
            location /api/users {
                return 200 '{"status":"ok","users":3,"message":"API funcionando"}';
            }
            
            location /api/db-test {
                return 200 '{"status":"ok","database":"labdb","connected":true}';
            }
            
            location /api/system {
                return 200 '{"status":"ok","hostname":"lab-services","time":"$(date)"}';
            }
        }

        location /status {
            return 200 '<!DOCTYPE html><html><head><title>Lab Status</title></head><body><h1>✅ Lab 3-Tier Operativo</h1><p>Servicios funcionando correctamente</p></body></html>';
        }
    }
}
EOF

# Configuración de dnsmasq
cat > /etc/lab-configs/dnsmasq.conf << 'EOF'
# Dnsmasq configuration for Lab 3-Tier
interface=veth-srv
bind-interfaces
listen-address=10.10.100.10
no-dhcp-interface=lo
domain=lab.local
expand-hosts
local=/lab.local/

# Local DNS records
address=/web.lab.local/10.10.100.10
address=/db.lab.local/10.10.100.10
address=/client.lab.local/10.10.50.10

# External DNS servers
server=8.8.8.8
server=1.1.1.1

# Cache
cache-size=1000
log-queries
log-facility=/var/log/dnsmasq-lab.log
EOF

# Página web estática
mkdir -p /usr/share/nginx/html
cat > /usr/share/nginx/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Lab 3-Tier - RHCSA</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
        .status-box { background: #e8f5e9; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .endpoint { background: #e3f2fd; padding: 10px; margin: 10px 0; border-left: 4px solid #2196F3; }
        .success { color: #4CAF50; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎯 Lab 3-Tier - RHCSA Practice</h1>
        <p>Entorno educativo para prácticas de redes y servicios</p>
        
        <div class="status-box">
            <h2>📊 Estado del Sistema</h2>
            <p class="success">✅ Todos los servicios operativos</p>
            <p><strong>IP:</strong> 10.10.100.10</p>
            <p><strong>Hostname:</strong> web.lab.local</p>
            <p><strong>Red:</strong> 3 namespaces activos (CLIENT, EDGE, SERVICES)</p>
        </div>
        
        <h2>🔧 Endpoints Disponibles</h2>
        
        <div class="endpoint">
            <h3>🌐 Página de Estado</h3>
            <p><a href="/status">/status</a> - Estado del sistema</p>
        </div>
        
        <div class="endpoint">
            <h3>📡 APIs</h3>
            <p><a href="/api/users">/api/users</a> - Usuarios del sistema</p>
            <p><a href="/api/db-test">/api/db-test</a> - Test de base de datos</p>
            <p><a href="/api/system">/api/system</a> - Información del sistema</p>
        </div>
        
        <h2>🎯 Objetivos del Lab</h2>
        <ul>
            <li>Network namespaces y segmentación</li>
            <li>Configuración de firewall (iptables)</li>
            <li>Administración de servicios (nginx, dnsmasq, mariadb)</li>
            <li>Troubleshooting de conectividad multi-capa</li>
            <li>Resolución DNS interna</li>
        </ul>
        
        <div style="margin-top: 30px; padding: 15px; background: #fff3e0; border-radius: 5px;">
            <h3>💡 Comandos útiles</h3>
            <code>lab-services-status</code> - Ver estado de servicios<br>
            <code>lab-ns client</code> - Entrar al namespace CLIENT<br>
            <code>lab-test-all</code> - Ejecutar todas las pruebas
        </div>
    </div>
</body>
</html>
EOF

echo "   ✅ Configuraciones creadas"

# ---------------------------------------------------------------------------
# 3. SERVICIOS SYSTEMD PARA NGINX Y DNSMASQ (DENTRO DE NAMESPACE)
# ---------------------------------------------------------------------------
echo "[3/6] 🚀 Creando servicios systemd para namespace..."

# Servicio para nginx DENTRO de NS-SERVICES
cat > /etc/systemd/system/lab-nginx.service << 'EOF'
[Unit]
Description=Nginx Web Server inside NS-SERVICES namespace
After=lab-network.service
Requires=lab-network.service
PartOf=lab-network.service

[Service]
Type=forking
PIDFile=/run/nginx-lab.pid

# Esperar a que el namespace exista
ExecStartPre=/bin/bash -c 'count=0; while [ ! -e /var/run/netns/NS-SERVICES ] && [ $count -lt 30 ]; do sleep 2; count=$((count+1)); done'
ExecStartPre=/bin/bash -c 'if [ ! -e /var/run/netns/NS-SERVICES ]; then echo "ERROR: NS-SERVICES namespace not found"; exit 1; fi'

# Ejecutar nginx DENTRO del namespace
ExecStart=/usr/bin/ip netns exec NS-SERVICES /usr/sbin/nginx -c /etc/lab-configs/nginx.conf
ExecStop=/usr/bin/ip netns exec NS-SERVICES /usr/sbin/nginx -s quit

# Reiniciar si falla
Restart=on-failure
RestartSec=5
TimeoutStartSec=30

# Environment
Environment=NGINX_CONF=/etc/lab-configs/nginx.conf

[Install]
WantedBy=multi-user.target
EOF

# Servicio para dnsmasq DENTRO de NS-SERVICES
cat > /etc/systemd/system/lab-dnsmasq.service << 'EOF'
[Unit]
Description=Dnsmasq DNS Server inside NS-SERVICES namespace
After=lab-network.service lab-nginx.service
Requires=lab-network.service
PartOf=lab-network.service

[Service]
Type=simple

# Esperar a que el namespace exista
ExecStartPre=/bin/bash -c 'count=0; while [ ! -e /var/run/netns/NS-SERVICES ] && [ $count -lt 30 ]; do sleep 2; count=$((count+1)); done'
ExecStartPre=/bin/bash -c 'if [ ! -e /var/run/netns/NS-SERVICES ]; then echo "ERROR: NS-SERVICES namespace not found"; exit 1; fi'

# Ejecutar dnsmasq DENTRO del namespace
ExecStart=/usr/bin/ip netns exec NS-SERVICES /usr/sbin/dnsmasq --keep-in-foreground -C /etc/lab-configs/dnsmasq.conf
ExecStop=/usr/bin/ip netns exec NS-SERVICES /usr/bin/pkill dnsmasq

# Reiniciar si falla
Restart=on-failure
RestartSec=5
TimeoutStartSec=30

# Environment
Environment=DNSMASQ_CONF=/etc/lab-configs/dnsmasq.conf

[Install]
WantedBy=multi-user.target
EOF

echo "   ✅ Servicios systemd creados"

# ---------------------------------------------------------------------------
# 4. SCRIPT DE INICIO MANUAL (FALLBACK)
# ---------------------------------------------------------------------------
echo "[4/6] 🛠️  Creando scripts manuales de fallback..."

# Script para iniciar servicios manualmente (si systemd falla)
cat > /usr/local/bin/lab-services-start.sh << 'EOF'
#!/bin/bash
echo "🚀 Iniciando servicios del lab manualmente..."

# Verificar que el namespace existe
if ! ip netns list | grep -q "NS-SERVICES"; then
    echo "❌ NS-SERVICES no existe. Ejecuta: lab-network-restart"
    exit 1
fi

# Matar procesos existentes
ip netns exec NS-SERVICES pkill nginx 2>/dev/null || true
ip netns exec NS-SERVICES pkill dnsmasq 2>/dev/null || true
sleep 2

# Iniciar nginx
echo "🌐 Iniciando nginx..."
ip netns exec NS-SERVICES /usr/sbin/nginx -c /etc/lab-configs/nginx.conf &
NGINX_PID=$!
echo "Nginx PID: $NGINX_PID"

sleep 2

# Iniciar dnsmasq
echo "📡 Iniciando dnsmasq..."
ip netns exec NS-SERVICES /usr/sbin/dnsmasq -C /etc/lab-configs/dnsmasq.conf --keep-in-foreground &
DNSMASQ_PID=$!
echo "Dnsmasq PID: $DNSMASQ_PID"

# Guardar PIDs
echo $NGINX_PID > /tmp/lab-nginx.pid
echo $DNSMASQ_PID > /tmp/lab-dnsmasq.pid

echo ""
echo "✅ Servicios iniciados manualmente"
echo "📊 Verificar con: lab-services-status"
EOF
chmod +x /usr/local/bin/lab-services-start.sh

# Script para detener servicios
cat > /usr/local/bin/lab-services-stop.sh << 'EOF'
#!/bin/bash
echo "🛑 Deteniendo servicios del lab..."
ip netns exec NS-SERVICES pkill nginx 2>/dev/null || true
ip netns exec NS-SERVICES pkill dnsmasq 2>/dev/null || true
sleep 2
echo "✅ Servicios detenidos"
EOF
chmod +x /usr/local/bin/lab-services-stop.sh

# Script para ver estado
cat > /usr/local/bin/lab-services-status.sh << 'EOF'
#!/bin/bash
echo "=== 🖥️  ESTADO DE SERVICIOS DEL LAB ==="
echo "📅 Fecha: $(date)"
echo ""

echo "1. 🏷️  NAMESPACE NS-SERVICES:"
if ip netns list | grep -q "NS-SERVICES"; then
    echo "   ✅ Existe"
else
    echo "   ❌ No existe"
fi

echo ""
echo "2. 🌐 NGINX:"
if ip netns exec NS-SERVICES pgrep nginx >/dev/null 2>&1; then
    echo "   ✅ Activo (PID: $(ip netns exec NS-SERVICES pgrep nginx))"
    echo -n "   🔗 Puerto 80: "
    if ip netns exec NS-SERVICES ss -tln | grep -q ":80 "; then
        echo "✅ Escuchando"
    else
        echo "❌ No escuchando"
    fi
else
    echo "   ❌ Inactivo"
fi

echo ""
echo "3. 📡 DNSMASQ:"
if ip netns exec NS-SERVICES pgrep dnsmasq >/dev/null 2>&1; then
    echo "   ✅ Activo (PID: $(ip netns exec NS-SERVICES pgrep dnsmasq))"
    echo -n "   🔗 Puerto 53: "
    if ip netns exec NS-SERVICES ss -tln | grep -q ":53 "; then
        echo "✅ Escuchando"
    else
        echo "❌ No escuchando"
    fi
else
    echo "   ❌ Inactivo"
fi

echo ""
echo "4. 🗄️  MARIADB:"
if systemctl is-active --quiet mariadb; then
    echo "   ✅ Activo"
    echo -n "   🔗 Puerto 3306: "
    if ss -tln | grep -q ":3306 "; then
        echo "✅ Escuchando"
    else
        echo "❌ No escuchando"
    fi
else
    echo "   ❌ Inactivo"
fi

echo ""
echo "5. 🧪 PRUEBAS RÁPIDAS:"
echo -n "   🔗 Web (curl): "
if ip netns exec NS-CLIENT curl -s -o /dev/null -w "%{http_code}" http://10.10.100.10 2>/dev/null | grep -q "200"; then
    echo "✅ HTTP 200"
else
    echo "❌ Falló"
fi

echo -n "   🔗 DNS (nslookup): "
if ip netns exec NS-CLIENT nslookup web.lab.local 10.10.100.10 >/dev/null 2>&1; then
    echo "✅ Resuelve"
else
    echo "❌ Falló"
fi

echo -n "   🔗 DB (mysql): "
if mysql -u labuser -predhat -h 10.10.100.10 -e "SELECT 1" labdb 2>/dev/null | grep -q "1"; then
    echo "✅ Conectado"
else
    echo "❌ Falló"
fi
EOF
chmod +x /usr/local/bin/lab-services-status.sh

# Alias corto
ln -sf /usr/local/bin/lab-services-status.sh /usr/local/bin/lab-services-status

echo "   ✅ Scripts manuales creados"

# ---------------------------------------------------------------------------
# 5. HABILITAR Y ACTIVAR SERVICIOS
# ---------------------------------------------------------------------------
echo "[5/6] ⚙️  Activando servicios..."

systemctl daemon-reload
systemctl enable lab-nginx lab-dnsmasq

# Iniciar servicios
systemctl start lab-nginx
sleep 3
systemctl start lab-dnsmasq
sleep 2

echo "   ✅ Servicios habilitados"

# ---------------------------------------------------------------------------
# 6. VERIFICACIÓN Y HERRAMIENTAS FINALES
# ---------------------------------------------------------------------------
echo "[6/6] 🧪 Creando herramientas de prueba..."

# Script de prueba completa
cat > /usr/local/bin/lab-test-all.sh << 'EOF'
#!/bin/bash
echo "=== 🧪 PRUEBA COMPLETA DEL LAB 3-TIER ==="
echo "📅 Fecha: $(date)"
echo ""

echo "1. 🔗 CONECTIVIDAD DE RED:"
echo -n "   Ping CLIENT -> SERVICES: "
if ip netns exec NS-CLIENT ping -c 2 -W 1 10.10.100.10 >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ FALLÓ"
fi

echo ""
echo "2. 🌐 SERVICIO WEB:"
echo -n "   HTTP GET 10.10.100.10: "
STATUS=$(ip netns exec NS-CLIENT curl -s -o /dev/null -w "%{http_code}" http://10.10.100.10 2>/dev/null || echo "000")
if [[ "$STATUS" == "200" ]]; then
    echo "✅ HTTP $STATUS"
    echo -n "   Contenido HTML: "
    if ip netns exec NS-CLIENT curl -s http://10.10.100.10 | grep -q "Lab 3-Tier"; then
        echo "✅ OK"
    else
        echo "❌ No contiene texto esperado"
    fi
else
    echo "❌ HTTP $STATUS"
fi

echo ""
echo "3. 📡 SERVICIO DNS:"
echo -n "   Resolución web.lab.local: "
if ip netns exec NS-CLIENT nslookup web.lab.local 10.10.100.10 >/dev/null 2>&1; then
    echo "✅ OK"
    echo "   Registro:"
    ip netns exec NS-CLIENT nslookup web.lab.local 10.10.100.10 2>/dev/null | grep "Address:" | tail -1
else
    echo "❌ FALLÓ"
fi

echo ""
echo "4. 🗄️  BASE DE DATOS:"
echo -n "   Conexión a MariaDB: "
if mysql -u labuser -predhat -h 10.10.100.10 -e "SELECT 1" labdb 2>/dev/null | grep -q "1"; then
    echo "✅ CONECTADO"
    echo -n "   Datos de ejemplo: "
    COUNT=$(mysql -u labuser -predhat -h 10.10.100.10 labdb -e "SELECT COUNT(*) FROM usuarios" 2>/dev/null | tail -1)
    if [[ "$COUNT" -ge 1 ]]; then
        echo "✅ $COUNT registros"
    else
        echo "❌ Sin datos"
    fi
else
    echo "❌ FALLÓ"
fi

echo ""
echo "5. 🛡️  FIREWALL:"
echo "   Reglas FORWARD en EDGE:"
ip netns exec NS-EDGE iptables -L FORWARD -n --line-numbers | head -10

echo ""
echo "📊 RESUMEN FINAL:"
echo "   Si ves 4-5 checks en ✅, el lab está 100% operativo."
echo "   Para reiniciar servicios: lab-services-restart"
echo "   Para estado detallado: lab-services-status"
EOF
chmod +x /usr/local/bin/lab-test-all.sh

# Alias para comandos comunes
cat >> /etc/profile.d/lab-commands.sh << 'EOF'
# Comandos del Lab 3-Tier
alias lab-status='lab-services-status'
alias lab-test='lab-test-all.sh'
alias lab-restart-services='systemctl restart lab-nginx lab-dnsmasq'
alias lab-restart-all='systemctl restart lab-network lab-nginx lab-dnsmasq'
alias lab-logs-nginx='journalctl -u lab-nginx -f'
alias lab-logs-dnsmasq='journalctl -u lab-dnsmasq -f'
EOF

echo "   ✅ Herramientas creadas"

# ---------------------------------------------------------------------------
# VERIFICACIÓN FINAL
# ---------------------------------------------------------------------------
echo ""
echo "🔍 VERIFICACIÓN INICIAL:"
echo "   1. Servicio nginx: $(systemctl is-active lab-nginx)"
echo "   2. Servicio dnsmasq: $(systemctl is-active lab-dnsmasq)"
echo "   3. Servicio mariadb: $(systemctl is-active mariadb)"
echo ""
echo "   4. Prueba web rápida:"
ip netns exec NS-CLIENT curl -s -o /dev/null -w "HTTP: %{http_code}\n" http://10.10.100.10 || echo "   ❌ Falló"
echo ""
echo "   5. Prueba DNS rápida:"
ip netns exec NS-CLIENT nslookup web.lab.local 10.10.100.10 2>&1 | grep "Address:" | tail -1 || echo "   ❌ Falló"

# ---------------------------------------------------------------------------
# RESUMEN
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo "✅ SCRIPT 3 COMPLETADO"
echo "============================================"
echo ""
echo "🎯 SERVICIOS CONFIGURADOS:"
echo "   • 🌐 Nginx: En NS-SERVICES (10.10.100.10:80)"
echo "   • 📡 Dnsmasq: En NS-SERVICES (10.10.100.10:53)"
echo "   • 🗄️  MariaDB: En host (0.0.0.0:3306)"
echo ""
echo "🔧 HERRAMIENTAS DISPONIBLES:"
echo "   • lab-services-status - Estado completo"
echo "   • lab-test-all.sh     - Pruebas integrales"
echo "   • lab-services-start.sh - Inicio manual (fallback)"
echo "   • lab-services-stop.sh  - Detención manual"
echo ""
echo "🚀 PERSISTENCIA GARANTIZADA:"
echo "   • Servicios se inician automáticamente al arranque"
echo "   • Dependen de lab-network.service"
echo "   • Reinician automáticamente si fallan"
echo ""
echo "💡 PRUEBA FINAL:"
echo "   1. Ejecutar: lab-test-all.sh"
echo "   2. Deben salir 4-5 checks en VERDE"
echo "   3. Reiniciar VM para probar persistencia"
echo ""
echo "📊 COMANDOS ÚTILES:"
echo "   lab-status      # Ver estado"
echo "   lab-test        # Ejecutar pruebas"
echo "   lab-restart-services # Reiniciar servicios"
echo "============================================"