#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   3 de 5 – Aprovisionamiento de Lógica y Datos (Application Layer)
# ============================================================================
#
# OBJETIVO DE ESTE SCRIPT:
#   Preparar la capa lógica del laboratorio una vez que la infraestructura
#   de red global (Script 2) ya está operativa y persistente.
#
# ESTE SCRIPT SE ENCARGA DE:
#   1) Endurecer y configurar MariaDB en el BÚNKER (NS-STORAGE).
#   2) Crear y mantener una base de datos de estado del laboratorio (labdb).
#   3) Generar Config-Store centralizado para servicios por zona:
#        - Nginx en ALEMANIA (NS-SERVICES)
#        - Aplicación web con conexión a DB
#   4) Desplegar contenido web geolocalizado.
#
# ARQUITECTURA NUEVA:
#   - Base de Datos: BÚNKER (NS-STORAGE, 10.90.0.50)
#   - Servicio Web: ALEMANIA (NS-SERVICES, 10.10.0.10)
#   - Acceso DB: Solo desde ALEMANIA e INDIA (vía firewall Script 2)
#
# ---------------------------------------------------------------------------
# VALIDACIONES OBLIGATORIAS PREVIAS (SCRIPT 2 – GLOBAL NETWORK)
#
# Antes de ejecutar este Script 3, DEBE confirmar que:
#
# 1) Los namespaces existen:
#    ip netns list
#    → NS-ROUTER, NS-SERVICES, NS-CLIENT, NS-DEV, NS-STORAGE, NS-SYSADMIN
#
# 2) El router core está activo:
#    ip netns exec NS-ROUTER ip addr show
#    → Interfaces v-nrsrv, v-nrcli, v-nrdev, v-nrdata, v-nradm con IPs .1
#
# 3) La conectividad básica funciona:
#    ip netns exec NS-CLIENT ping -c 2 10.10.0.10  # China → Alemania
#    ip netns exec NS-SERVICES ping -c 2 10.90.0.50 # Alemania → Búnker
#
# 4) El firewall está activo:
#    ip netns exec NS-ROUTER iptables -L FORWARD -n
#    → Verificar reglas de ACCEPT/DROP
#
# 5) Validación rápida:
#    lab-network-status
#    → Todos los checks deben mostrar estado esperado
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
#   - Script 4: Ejecución de servicios dentro de namespaces,
#     utilizando las configuraciones generadas aquí.
# ============================================================================

set -e

echo "=== 🖥️  SCRIPT 3: PROVISIÓN PARA ARQUITECTURA GLOBAL ==="
echo "📅 Fecha: $(date)"
echo "🌍 Topología: Multi-Sede con Router Core"

# ---------------------------------------------------------------------------
# 1. VERIFICACIÓN DE INTEGRIDAD DE RED (SCRIPT 2)
# ---------------------------------------------------------------------------
echo "[1/5] 🔍 Verificando infraestructura global..."

# Verificar que todos los namespaces existen
REQUIRED_NS=("NS-ROUTER" "NS-SERVICES" "NS-CLIENT" "NS-DEV" "NS-STORAGE" "NS-SYSADMIN")
for ns in "${REQUIRED_NS[@]}"; do
    if ! ip netns list | grep -q "$ns"; then
        echo "❌ ERROR: Namespace '$ns' no existe. Ejecute Script 2."
        exit 1
    fi
    echo "   ✅ Namespace $ns presente."
done

# Verificar IPs críticas
echo "[2/5] 🌐 Verificando conectividad entre sedes..."

# China puede llegar a Alemania (Web)
if ! ip netns exec NS-CLIENT ping -c 1 -W 1 10.10.0.10 > /dev/null; then
    echo "⚠️  ADVERTENCIA: China → Alemania no responde (¿firewall bloqueando?)"
    echo "   Continuando asumiendo política de seguridad activa..."
fi

# Alemania puede llegar al Búnker (DB)
if ! ip netns exec NS-SERVICES ping -c 1 -W 1 10.90.0.50 > /dev/null; then
    echo "❌ ERROR: Alemania → Búnker no responde. Verifique Script 2."
    exit 1
fi
echo "   ✅ Conectividad básica verificada."

# ---------------------------------------------------------------------------
# 2. MARIADB – PREPARACIÓN ESTRUCTURAL (DATOS PARA EL BÚNKER)
# ---------------------------------------------------------------------------
echo "[3/5] 🗄️  Configurando MariaDB (Preparación de datos)..."

# Instalar si no está presente (en el Host)
if ! command -v mysql &> /dev/null; then
    dnf install -y mariadb-server mariadb
fi

# Iniciamos MariaDB en el Host SOLO para inyectar la configuración inicial
systemctl start mariadb

# 1. Hardening básico + creación de DB y Usuarios
mysql -u root << 'MYSQL_SCRIPT'
    ALTER USER 'root'@'localhost' IDENTIFIED BY 'BunkerSecure2024!';
    DELETE FROM mysql.user WHERE User='';
    DROP DATABASE IF EXISTS test;
    CREATE DATABASE IF NOT EXISTS lab_global;
    
    -- Usuarios autorizados por IP (Según red del Script 2)
    CREATE USER IF NOT EXISTS 'web_srv'@'10.10.0.10' IDENTIFIED BY 'WebToDB123';
    CREATE USER IF NOT EXISTS 'dev_ops'@'10.30.0.30' IDENTIFIED BY 'DevAccess789';
    CREATE USER IF NOT EXISTS 'sys_admin'@'172.16.0.100' IDENTIFIED BY 'AdminFullAccess!';
    
    -- Privilegios
    GRANT SELECT, INSERT, UPDATE, DELETE ON lab_global.* TO 'web_srv'@'10.10.0.10';
    GRANT ALL PRIVILEGES ON lab_global.* TO 'dev_ops'@'10.30.0.30';
    GRANT ALL PRIVILEGES ON *.* TO 'sys_admin'@'172.16.0.100' WITH GRANT OPTION;
    FLUSH PRIVILEGES;
MYSQL_SCRIPT

# 2. Creación de tablas de estado
mysql -u root -p'BunkerSecure2024!' lab_global << 'DB_TABLES'
    CREATE TABLE IF NOT EXISTS global_status (
        id INT AUTO_INCREMENT PRIMARY KEY,
        sede VARCHAR(50),
        componente VARCHAR(50),
        estado VARCHAR(20),
        ultima_verificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY idx_sede_componente (sede, componente)
    );
    INSERT INTO global_status (sede, componente, estado) VALUES
        ('BUNKER',   'MariaDB',     'OPERATIVO'),
        ('ALEMANIA', 'Nginx',       'PENDIENTE'),
        ('CHINA',    'Cliente_Web', 'ACTIVO'),
        ('INDIA',    'Desarrollo',  'ACTIVO'),
        ('SYSADMIN', 'Acceso_Total','ACTIVO')
    ON DUPLICATE KEY UPDATE estado = VALUES(estado);
DB_TABLES

# 3. Ajustar configuración de red (Escuchar en todas las IPs virtuales)
# Esto asegura que cuando el proceso suba en el Búnker, acepte conexiones externas
sed -i 's/^#bind-address.*/bind-address = 0.0.0.0/' /etc/my.cnf.d/mariadb-server.cnf 2>/dev/null || \
sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/my.cnf.d/mariadb-server.cnf 2>/dev/null || true

# 4. Apagamos el servicio en el Host
# Importante: No queremos que el Host use el puerto 3306, lo queremos libre para el Búnker
systemctl stop mariadb

echo "   ✅ Datos de MariaDB preparados y guardados en disco."

# ---------------------------------------------------------------------------
# 3. CONFIG-STORE CENTRALIZADO (POR ZONA GEOGRÁFICA)
# ---------------------------------------------------------------------------
echo "[4/5] ⚙️  Generando Config-Store global..."

mkdir -p /etc/lab-configs/global

# NGINX – Para ALEMANIA (NS-SERVICES)
cat > /etc/lab-configs/global/nginx-alemania.conf << 'NGINX_GLOBAL'
user nginx;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logs con formato extendido
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;
    
    # Configuración del sitio web corporativo
    server {
        listen 10.10.0.10:80;
        server_name empresa-global.com www.empresa-global.com;
        
        root /usr/share/nginx/html;
        index index.html index.php;
        
        # Página principal
        location / {
            try_files $uri $uri/ =404;
        }
        
        # API para consultar estado de DB (solo desde Alemania)
        location /api/status {
            # Proxy a script PHP que consulta DB en Búnker
            fastcgi_pass unix:/run/php-fpm/www.sock;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root/api_status.php;
            
            # Seguridad: solo IPs autorizadas
            allow 10.10.0.0/24;
            allow 172.16.0.0/24;  # SysAdmin
            deny all;
        }
        
        # Acceso desde China (según política de negocio)
        location /public/ {
            # Contenido público para China
            alias /usr/share/nginx/html/public/;
            
            # Headers de seguridad
            add_header X-Content-Type-Options "nosniff";
            add_header X-Frame-Options "SAMEORIGIN";
        }
    }
    
    # Sitio de administración (solo SysAdmin)
    server {
        listen 10.10.0.10:8080;
        server_name admin.empresa-global.com;
        
        root /usr/share/nginx/admin;
        index index.html;
        
        # Autenticación básica
        auth_basic "Área de Administración";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        # Solo SysAdmin puede acceder
        allow 172.16.0.0/24;
        deny all;
    }
}
NGINX_GLOBAL

# PHP-FPM Config – Para conexión a DB en Búnker
cat > /etc/lab-configs/global/php-fpm.conf << 'PHP_FPM'
[global]
pid = /run/php-fpm/php-fpm.pid
error_log = /var/log/php-fpm/error.log

[www]
user = nginx
group = nginx
listen = /run/php-fpm/www.sock
listen.owner = nginx
listen.group = nginx
listen.mode = 0660

pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3

; Configuración para conexión a DB en Búnker
env[DB_HOST] = 10.90.0.50
env[DB_NAME] = lab_global
env[DB_USER] = web_srv
env[DB_PASS] = WebToDB123
PHP_FPM

# Script PHP para consultar DB
cat > /etc/lab-configs/global/api_status.php << 'PHP_API'
<?php
header('Content-Type: application/json');

// Credenciales desde variables de entorno
$db_host = getenv('DB_HOST') ?: '10.90.0.50';
$db_name = getenv('DB_NAME') ?: 'lab_global';
$db_user = getenv('DB_USER') ?: 'web_srv';
$db_pass = getenv('DB_PASS') ?: 'WebToDB123';

// Solo permitir desde redes autorizadas
$client_ip = $_SERVER['REMOTE_ADDR'];
$allowed_nets = ['10.10.0.0/24', '172.16.0.0/24'];

$allowed = false;
foreach ($allowed_nets as $net) {
    if (ip_in_network($client_ip, $net)) {
        $allowed = true;
        break;
    }
}

if (!$allowed) {
    http_response_code(403);
    echo json_encode(['error' => 'Acceso no autorizado']);
    exit;
}

try {
    $pdo = new PDO(
        "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4",
        $db_user,
        $db_pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    
    // Consultar estado global
    $stmt = $pdo->query("SELECT sede, componente, estado FROM global_status ORDER BY sede");
    $status = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Información del servidor
    $server_info = [
        'servidor' => gethostname(),
        'ip' => $_SERVER['SERVER_ADDR'],
        'zona' => 'ALEMANIA 🇩🇪',
        'timestamp' => date('c')
    ];
    
    echo json_encode([
        'success' => true,
        'server' => $server_info,
        'status' => $status,
        'db_connection' => 'OK'
    ]);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Error de base de datos',
        'message' => $e->getMessage()
    ]);
}

function ip_in_network($ip, $cidr) {
    list($network, $mask) = explode('/', $cidr);
    $ip_long = ip2long($ip);
    $network_long = ip2long($network);
    $mask_long = ~((1 << (32 - $mask)) - 1);
    return ($ip_long & $mask_long) == ($network_long & $mask_long);
}
?>
PHP_API

# Configuración para INDIA (NS-DEV) - Herramientas de desarrollo
cat > /etc/lab-configs/global/dev-tools.conf << 'DEV_TOOLS'
# Herramientas de desarrollo para India
# Acceso completo al Búnker para desarrollo

[mysql_client]
host=10.90.0.50
port=3306
user=dev_ops
password=DevAccess789
database=lab_global

[backup_scripts]
daily_backup=/usr/local/bin/backup-db.sh
log_dir=/var/log/backups
retention_days=7

[monitoring]
ping_interval=60
alert_email=devops@empresa-global.com
DEV_TOOLS

echo "   ✅ Config-Store global creado en /etc/lab-configs/global"

# ---------------------------------------------------------------------------
# 4. CONTENIDO WEB GEO-LOCALIZADO
# ---------------------------------------------------------------------------
echo "[5/5] 🌐 Generando contenido web por sede..."

# Directorios para diferentes sedes
mkdir -p /usr/share/nginx/{html,admin,public}

# Sitio principal (Alemania)
cat > /usr/share/nginx/html/index.html << 'HTML_MAIN'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Empresa Global - Sede Central Alemania</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f0f0f0; }
        .container { max-width: 800px; margin: auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        .flag { font-size: 2em; margin-right: 10px; }
        .header { display: flex; align-items: center; margin-bottom: 30px; }
        .section { margin: 20px 0; padding: 15px; border-left: 4px solid #007acc; background: #f9f9f9; }
        .api-test { background: #e8f4fc; padding: 15px; border-radius: 5px; margin-top: 20px; }
        button { background: #007acc; color: white; border: none; padding: 10px 15px; border-radius: 5px; cursor: pointer; }
        button:hover { background: #005a9c; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <span class="flag">🇩🇪</span>
            <h1>Empresa Global - Sede Central</h1>
        </div>
        
        <div class="section">
            <h2>🌍 Arquitectura Global</h2>
            <p><strong>Zona:</strong> Alemania (Producción Web)</p>
            <p><strong>IP:</strong> 10.10.0.10</p>
            <p><strong>Base de Datos:</strong> Búnker Seguro (10.90.0.50)</p>
        </div>
        
        <div class="section">
            <h2>🔗 Políticas de Acceso</h2>
            <ul>
                <li>✅ <strong>China:</strong> Solo contenido público</li>
                <li>✅ <strong>India:</strong> Acceso completo a DB para desarrollo</li>
                <li>✅ <strong>SysAdmin:</strong> Acceso total desde Home Office</li>
                <li>❌ <strong>China → Búnker:</strong> Bloqueado por seguridad</li>
            </ul>
        </div>
        
        <div class="api-test">
            <h3>🧪 Test de Conexión a Base de Datos</h3>
            <p>Verifica el estado de toda la infraestructura:</p>
            <button onclick="testAPI()">Consultar Estado Global</button>
            <div id="api-result" style="margin-top: 10px;"></div>
        </div>
        
        <div class="section">
            <h2>📊 Golden Base Image</h2>
            <p>Esta es una instancia de la imagen base empresarial con:</p>
            <ul>
                <li>Segmentación de red por zonas geográficas</li>
                <li>Firewall stateful en router core</li>
                <li>Base de datos centralizada en búnker seguro</li>
                <li>Contenido web geo-localizado</li>
            </ul>
        </div>
    </div>
    
    <script>
    async function testAPI() {
        const resultDiv = document.getElementById('api-result');
        resultDiv.innerHTML = '<p>Consultando API...</p>';
        
        try {
            const response = await fetch('/api/status');
            const data = await response.json();
            
            if (data.success) {
                let html = '<h4>✅ Estado de la Infraestructura:</h4>';
                html += '<p><strong>Servidor:</strong> ' + data.server.zona + '</p>';
                html += '<table border="1" style="width:100%; border-collapse:collapse;">';
                html += '<tr><th>Sede</th><th>Componente</th><th>Estado</th></tr>';
                
                data.status.forEach(item => {
                    html += `<tr>
                        <td>${item.sede}</td>
                        <td>${item.componente}</td>
                        <td style="color: ${item.estado === 'OPERATIVO' ? 'green' : 'orange'}">
                            ${item.estado}
                        </td>
                    </tr>`;
                });
                
                html += '</table>';
                resultDiv.innerHTML = html;
            } else {
                resultDiv.innerHTML = '<p style="color:red;">❌ Error: ' + data.error + '</p>';
            }
        } catch (error) {
            resultDiv.innerHTML = '<p style="color:red;">❌ Error de conexión: ' + error.message + '</p>';
        }
    }
    </script>
</body>
</html>
HTML_MAIN

# Contenido público para China
cat > /usr/share/nginx/public/index.html << 'HTML_CHINA'
<!DOCTYPE html>
<html>
<head>
    <title>Empresa Global - Portal Público</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; }
        .china-flag { font-size: 3em; margin-bottom: 20px; }
        .warning { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; margin: 20px auto; max-width: 600px; }
    </style>
</head>
<body>
    <div class="china-flag">🇨🇳</div>
    <h1>Bienvenido desde China</h1>
    <p>Contenido público autorizado para clientes chinos.</p>
    
    <div class="warning">
        <strong>🔒 Política de Seguridad:</strong><br>
        Esta sede solo tiene acceso limitado al contenido web.<br>
        El acceso a bases de datos y sistemas internos está restringido.
    </div>
    
    <p>IP Cliente: 10.20.0.20</p>
    <p><small>Golden Image - Arquitectura Segura por Zonas</small></p>
</body>
</html>
HTML_CHINA

# Panel de administración (solo SysAdmin)
cat > /usr/share/nginx/admin/index.html << 'HTML_ADMIN'
<!DOCTYPE html>
<html>
<head>
    <title>Admin - Empresa Global</title>
    <style>
        body { font-family: monospace; background: #1a1a1a; color: #00ff00; padding: 20px; }
        .terminal { background: #000; padding: 20px; border-radius: 5px; }
        .prompt { color: #00ffff; }
        .command { color: #ffff00; }
        .output { color: #00ff00; }
    </style>
</head>
<body>
    <h1>🛡️ Panel de Administración - SysAdmin</h1>
    <p><strong>Acceso:</strong> Total e irrestricto</p>
    <p><strong>IP:</strong> 172.16.0.100</p>
    
    <div class="terminal">
        <p><span class="prompt">sysadmin@bunker:~$</span> <span class="command">sudo lab-network-status</span></p>
        <p class="output">=== 🛰️ AUDITORÍA DE SEGURIDAD GLOBAL ===</p>
        <p class="output">1. CHINA → ALEMANIA (Web): ✅ PERMITIDO</p>
        <p class="output">2. CHINA → BÚNKER (Datos): ❌ BLOQUEADO (Seguridad OK)</p>
        <p class="output">3. GERMANY → BÚNKER (DB): ✅ PERMITIDO</p>
        <p class="output">4. SYSADMIN → TODOS: ✅ PERMITIDO</p>
        <br>
        <p><span class="prompt">sysadmin@bunker:~$</span> <span class="command">mysql -h 10.90.0.50 -u sys_admin -p</span></p>
        <p class="output">Welcome to the MariaDB monitor. Commands end with ; or \g.</p>
        <p class="output">MariaDB [(none)]> SHOW DATABASES;</p>
        <p class="output">+--------------------+</p>
        <p class="output">| Database           |</p>
        <p class="output">+--------------------+</p>
        <p class="output">| lab_global         |</p>
        <p class="output">| information_schema |</p>
        <p class="output">| mysql              |</p>
        <p class="output">| performance_schema |</p>
        <p class="output">+--------------------+</p>
    </div>
    
    <p><small>🔐 Acceso privilegiado - Solo personal autorizado</small></p>
</body>
</html>
HTML_ADMIN

# ---------------------------------------------------------------------------
# FINAL
# ---------------------------------------------------------------------------
echo ""
echo "========================================================"
echo "✅ SCRIPT 3 ACTUALIZADO COMPLETADO CORRECTAMENTE"
echo "========================================================"
echo ""
echo "🌍 ARQUITECTURA GLOBAL CONFIGURADA:"
echo "   • 🗄️  MariaDB en BÚNKER (10.90.0.50:3306)"
echo "   • 🌐 Config-Store en /etc/lab-configs/global"
echo "   • 🇩🇪 Contenido web para Alemania"
echo "   • 🇨🇳 Contenido público para China"
echo "   • 🛡️  Panel admin para SysAdmin"
echo ""
echo "📊 BASE DE DATOS:"
echo "   • Usuario 'web_srv'@'10.10.0.10' (Alemania → Web)"
echo "   • Usuario 'dev_ops'@'10.30.0.30' (India → Desarrollo)"
echo "   • Usuario 'sys_admin'@'172.16.0.100' (SysAdmin → Total)"
echo ""
echo "➡️  Próximo paso: SCRIPT 4 (Despliegue de servicios en namespaces)"
echo "   Se instalarán Nginx, PHP-FPM en NS-SERVICES (Alemania)"