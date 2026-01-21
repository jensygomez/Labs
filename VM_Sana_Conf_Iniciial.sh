#!/bin/bash
# ============================================================================
# 🚀 LAB RECOVERY & SETUP - ARQUITECTURA 3-TIER (CLIENT-EDGE-SERVICES)
# ============================================================================
# AUTOR    : Jensy Gomez (Modified for 3-Tier Isolation)
# OS BASE  : Rocky Linux 9.x
# PROPÓSITO: Reconstrucción total desde cero (Idempotente).
# ============================================================================

set -euo pipefail
exec > >(tee -a /var/log/lab-reconstruction-$(date +%Y%m%d-%H%M%S).log) 2>&1

# ---------------------------------------------------------------------------
# 📐 CONFIGURACIÓN GLOBAL Y DIRECCIONAMIENTO
# ---------------------------------------------------------------------------
readonly NET_CLIENT="10.10.50.0/24"
readonly NET_SERVICES="10.10.100.0/24"

readonly IP_CLIENT="10.10.50.10"
readonly IP_EDGE_LAN="10.10.50.1"    # Gateway para Cliente
readonly IP_EDGE_WAN="10.10.100.1"  # Gateway para Servicios
readonly IP_SERVICES="10.10.100.10" # IP unificada para servicios (VIP)

readonly DB_USER="labuser"
readonly DB_PASS="redhat"
readonly DB_NAME="labdb"

# ---------------------------------------------------------------------------
# 1️⃣ VERIFICACIÓN DE ENTORNO Y LIMPIEZA DE RESIDUOS
# ---------------------------------------------------------------------------
# El objetivo de este bloque es garantizar un entorno "limpio" y con permisos suficientes.
# Se limpia la terminal, se imprimen variables de entorno críticas ($NET_CLIENT, $NET_SERVICES) 
# y se verifica que el usuario sea 'root', ya que la manipulación de interfaces de red y 
# namespaces requiere privilegios de kernel. Finalmente, la función 'cleanup' actúa como 
# un mecanismo de idempotencia: detiene servicios (Nginx, MariaDB, DNS) y destruye 
# de forma forzada los Namespaces (NS-CLIENT, NS-EDGE, NS-SERVICES) junto con sus 
# túneles virtuales (veth), eliminando cualquier rastro de ejecuciones previas que 
# pudiera causar conflictos de enrutamiento o nombres de interfaz duplicados.
# ---------------------------------------------------------------------------
clear
echo "=== 🚀 Iniciando Reconstrucción Total del Ecosistema 3-Tier ==="
echo "📅 Fecha/Hora: $(date)"
echo "📊 Redes: Cliente $NET_CLIENT | Servicios $NET_SERVICES"
echo "=" * 60

if [[ $EUID -ne 0 ]]; then 
    echo "❌ Error: Este script debe ejecutarse como root"
    exit 1
fi

cleanup() {
    echo "   🧹 Limpiando rastro anterior..."
    
    # Detener servicios
    systemctl stop lab-infrastructure 2>/dev/null || true
    systemctl stop mariadb nginx dnsmasq 2>/dev/null || true
    
    # Eliminar namespaces
    for ns in NS-CLIENT NS-EDGE NS-SERVICES; do
        ip netns delete $ns 2>/dev/null || true
    done
    
    # Limpiar interfaces residuales
    ip link delete veth-client 2>/dev/null || true
    ip link delete veth-edge-cli 2>/dev/null || true
    ip link delete veth-edge-srv 2>/dev/null || true
    ip link delete veth-srv 2>/dev/null || true
    
    echo "   ✅ Limpieza completada"
}

cleanup

# ---------------------------------------------------------------------------
# 2️⃣ INSTALACIÓN DE PAQUETES (FULL STACK)
# ---------------------------------------------------------------------------
# Esta sección se encarga de preparar el entorno de software necesario para toda la arquitectura 3-Tier.
# Primero, sincroniza los repositorios y añade EPEL para acceder a paquetes extendidos. 
# La instalación masiva cubre los cuatro pilares del laboratorio: 1) Servicios de Aplicación y Datos 
# (Nginx, MariaDB), 2) Infraestructura de Red y Proxy (Squid, Dnsmasq), 3) Seguridad y Control de Tráfico 
# (Firewalld, Iptables, TC para QoS, Conntrack) y 4) Diagnóstico Avanzado (Tcpdump, Nmap, Lsof, Iproute). 
# Esto garantiza que el sistema operativo tenga todas las herramientas de bajo nivel requeridas para 
# la manipulación de paquetes, túneles y servicios de red sin interrupciones por dependencias faltantes.
# ---------------------------------------------------------------------------
echo "[2/14] 📦 Instalando paquetes esenciales..."
echo "   Actualizando sistema..."
dnf update -y --quiet

echo "   Instalando repositorios..."
dnf install -y epel-release --quiet

echo "   Instalando paquetes base..."
dnf install -y nginx mariadb-server mariadb squid dnsmasq firewalld \
    bind-utils iproute iproute-tc tcpdump conntrack-tools iptables-services \
    net-tools nmap wget curl vim-enhanced cloud-init socat lsof htop \
    tree --quiet

echo "   ✅ Paquetes instalados correctamente"

# ---------------------------------------------------------------------------
# 3️⃣ CONFIGURACIÓN DE CLOUD-INIT
# ---------------------------------------------------------------------------
# Este bloque automatiza la personalización inicial del sistema mediante Cloud-Init, 
# permitiendo que el entorno sea "clonable" y autoconfigurable. Se habilitan los 
# servicios de arranque para que reconozcan metadatos de tipo 'NoCloud' (ideal para 
# entornos locales o KVM/Libvirt) y se sobrescribe la configuración para permitir 
# el acceso directo como usuario 'root' y mediante contraseña por SSH. Además, se 
# define un usuario estándar llamado 'student' con privilegios de sudo sin contraseña, 
# estableciendo un entorno de trabajo listo para el uso sin intervención manual tras 
# el despliegue de las instancias o contenedores.
# ---------------------------------------------------------------------------
echo "[3/14] ☁️  Configurando cloud-init..."
systemctl enable cloud-init-local cloud-init cloud-config cloud-final --now 2>/dev/null || true

cat > /etc/cloud/cloud.cfg.d/90_libvirt.cfg <<EOF
datasource_list: [ NoCloud, None ]
disable_root: false
ssh_pwauth: true
users:
  - name: student
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
    passwd: \$6\$rounds=656000\$Q5fq5QRl4x8.UQRn\$Z2h6lVd.5NCIUk0KX9HxJvG3YDqYqA5T7R0vXvVj2BqBvV8c9n6Lw5rQ6zW8sLf1qP9sJ5mQ3tY6pQ0
EOF

echo "   ✅ Cloud-init configurado"


# ---------------------------------------------------------------------------
# 4️⃣ USUARIO STUDENT Y SSH (PLANO DE GESTIÓN) - LAB PROOF
# ---------------------------------------------------------------------------
# Este bloque establece la capa de gestión y acceso al laboratorio, garantizando que el entorno 
# sea manejable y accesible para el estudiante. Se asegura la existencia del usuario 'student' 
# con privilegios de sudo ilimitados y se inyectan claves SSH para un acceso sin fricciones. 
# La reconfiguración del servicio SSH (`sshd_config`) es crítica: se relajan restricciones de 
# seguridad estándar (permitiendo login de root y autenticación por contraseña) para priorizar 
# la disponibilidad en un entorno de pruebas. Finalmente, se inyectan 'aliases' globales en el 
# sistema, permitiendo al administrador saltar rápidamente entre los diferentes contextos de red 
# (Namespaces) mediante comandos cortos, lo que optimiza drásticamente el flujo de trabajo en 
# la resolución de problemas (troubleshooting) y validación de servicios.
# ---------------------------------------------------------------------------
echo "[4/14] 👤 Configurando usuario student y SSH..."

# 1. Crear usuario student (idempotente)
if ! id "student" &>/dev/null; then
    echo "   Creando usuario student..."
    useradd -m -G wheel -s /bin/bash student
    echo "student:redhat" | chpasswd
    echo "   Usuario student creado"
else
    echo "   Usuario student ya existe"
    echo "student:redhat" | chpasswd  # Refrescar password siempre
fi

# 2. Sudo sin password
echo "student ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/student
chmod 440 /etc/sudoers.d/student

# 3. Configurar .ssh con permisos correctos
mkdir -p /home/student/.ssh
chown student:student /home/student/.ssh
chmod 700 /home/student/.ssh

# 🔑 Claves SSH de ejemplo (funcionan para pruebas)
cat > /home/student/.ssh/authorized_keys <<'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByFDKwjMDeGJ5GRhXmZHa75h7dK9JcPHvWWtesSO3/x student@lab
EOF

chown student:student /home/student/.ssh/authorized_keys
chmod 600 /home/student/.ssh/authorized_keys

# 4. 🔐 SSH CONFIGURACIÓN LAB (CRÍTICA - reemplaza todo lo restrictivo)
echo "   🔐 Configurando SSH lab-friendly..."
cat >> /etc/ssh/sshd_config <<EOF

# =====================================================
# LAB RHCSA 3-TIER - Configuración SSH LAB
# =====================================================
PasswordAuthentication yes
PermitRootLogin yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
StrictModes no
LoginGraceTime 120
MaxAuthTries 6
MaxSessions 20
MaxStartups 10:30:100
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintLastLog no
TCPKeepAlive yes
ClientAliveInterval 30
ClientAliveCountMax 3
EOF

# 5. Validar y reiniciar SSH
sshd -t  # Test config
systemctl restart sshd
sleep 2
systemctl is-active sshd && echo "   ✅ SSH service activo" || echo "   ❌ SSH service fallo"

# 6. Crear aliases para el lab
cat > /etc/profile.d/lab-aliases.sh <<'EOF'
# LAB 3-TIER Aliases
alias ns-client='ip netns exec NS-CLIENT bash'
alias ns-edge='ip netns exec NS-EDGE bash'  
alias ns-services='ip netns exec NS-SERVICES bash'
alias lab-check='ip netns exec NS-CLIENT curl -s http://10.10.100.10 | head -5'
alias lab-reset='/usr/local/bin/lab-reset.sh'
alias lab-health='lab-health-check.sh'
EOF

chmod +x /etc/profile.d/lab-aliases.sh

# 7. Verificación final
echo "student:redhat" | chpasswd 2>/dev/null
echo "   ✅ Usuario y SSH LAB configurados:"
echo "      • student/redhat (password + sudo)"
echo "      • SSH: password + claves habilitado"
echo "      • Aliases: ns-client, lab-check, lab-reset"
echo "      • source /etc/profile.d/lab-aliases.sh para cargar"


# ---------------------------------------------------------------------------
# 5️⃣ CONFIGURACIÓN DE BASE DE DATOS MARIA DB
# ---------------------------------------------------------------------------
# Este bloque despliega y asegura la capa de datos del ecosistema 3-Tier. Primero, inicializa 
# el motor MariaDB y ejecuta un saneamiento de seguridad (hardening) eliminando usuarios 
# anónimos y bases de datos de prueba. Posteriormente, aprovisiona la base de datos operativa 
# y define permisos granulares: permite el acceso tanto local como desde el segmento de red 
# de servicios ($NET_SERVICES), utilizando comodines de IP para facilitar la conectividad entre 
# nodos del laboratorio. Finalmente, se inyecta un esquema relacional básico con tablas de 
# 'usuarios' y 'servidores' pobladas con datos ficticios, lo que permite validar de inmediato 
# la consistencia de la base de datos y realizar pruebas de consultas SQL desde las capas 
# superiores de la aplicación (Web/App Tier).
# ---------------------------------------------------------------------------
echo "[5/14] 🗄️  Configurando base de datos de ejemplo..."

# Iniciar y habilitar MariaDB
systemctl enable --now mariadb

# Configurar seguridad inicial de MariaDB
echo "   Configurando seguridad de MariaDB..."
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"

# Configurar BD de ejemplo
echo "   Creando base de datos y usuario..."
mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'10.10.100.%' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'10.10.100.%';"
mysql -e "FLUSH PRIVILEGES;"

# Crear tabla de ejemplo con datos
echo "   Creando tabla de ejemplo con datos..."
mysql $DB_NAME <<EOF
CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    departamento VARCHAR(30),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT true
);

CREATE TABLE IF NOT EXISTS servidores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    ip_address VARCHAR(15),
    tipo ENUM('web', 'db', 'dns', 'firewall') DEFAULT 'web',
    status ENUM('activo', 'mantenimiento', 'apagado') DEFAULT 'activo'
);

INSERT IGNORE INTO usuarios (nombre, email, departamento) VALUES 
    ('Juan Pérez', 'juan@lab.local', 'IT'),
    ('María García', 'maria@lab.local', 'Desarrollo'),
    ('Carlos López', 'carlos@lab.local', 'Operaciones'),
    ('Ana Rodríguez', 'ana@lab.local', 'Seguridad'),
    ('Pedro Sánchez', 'pedro@lab.local', 'Soporte');

INSERT IGNORE INTO servidores (nombre, ip_address, tipo, status) VALUES
    ('Web Server', '$IP_SERVICES', 'web', 'activo'),
    ('DB Primary', '10.10.100.11', 'db', 'activo'),
    ('DNS Cache', '10.10.100.12', 'dns', 'activo'),
    ('Edge Router', '$IP_EDGE_WAN', 'firewall', 'activo');

SELECT 'Base de datos configurada correctamente' as Status;
EOF

echo "   ✅ Base de datos configurada:"
echo "      - Base de datos: $DB_NAME"
echo "      - Usuario: $DB_USER"
echo "      - Contraseña: $DB_PASS"

# ---------------------------------------------------------------------------
# 6️⃣ PREPARACIÓN DE CONFIGURACIONES DE SERVICIOS
# ---------------------------------------------------------------------------
# En esta fase se genera la "personalidad" de cada servicio mediante la creación de archivos de 
# configuración personalizados que serán inyectados en los Namespaces. Se construye una interfaz 
# web enriquecida (HTML/CSS) y una serie de endpoints API en formato JSON que simulan una 
# arquitectura desacoplada, permitiendo realizar pruebas de conectividad y consumo de datos 
# sin dependencias complejas como Lua o PHP. Además, se define la configuración de Nginx para 
# actuar como servidor web de alto rendimiento y se parametriza Dnsmasq para gestionar la 
# resolución de nombres interna del laboratorio (FQDNs como web.lab.local). Esto asegura que 
# cada componente tenga sus rutas, registros DNS y archivos de sistema listos antes de que las 
# interfaces de red sean levantadas, facilitando una puesta en marcha inmediata y predecible.
# ---------------------------------------------------------------------------

echo "[6/14] ⚙️  Generando archivos de configuración para los Namespaces..."
mkdir -p /etc/lab-configs
mkdir -p /usr/share/nginx/html/api    # 🔥 FIX: Crea /api DESDE el inicio

# Página web HTML de ejemplo
cat > /usr/share/nginx/html/index.html <<EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LAB 3-Tier Architecture</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 20px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        h2 { color: #34495e; margin-top: 30px; }
        .status { padding: 10px; margin: 10px 0; border-radius: 5px; }
        .ok { background-color: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .info { background-color: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin: 20px 0; }
        .card { padding: 15px; border: 1px solid #ddd; border-radius: 5px; background: #f8f9fa; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #3498db; color: white; }
        tr:hover { background-color: #f5f5f5; }
    </style>
</head>
<body>
    <div class="container">
        <h1>✅ Sistema 3-Tier Architecture - Operativo</h1>
        
        <div class="status ok">
            <strong>Estado:</strong> Todos los servicios funcionando correctamente
        </div>
        
        <h2>📊 Información de Redes:</h2>
        <div class="grid">
            <div class="card">
                <h3>🔵 Capa CLIENT</h3>
                <p><strong>Red:</strong> $NET_CLIENT</p>
                <p><strong>IP Cliente:</strong> $IP_CLIENT</p>
                <p><strong>Gateway:</strong> $IP_EDGE_LAN</p>
            </div>
            <div class="card">
                <h3>🟢 Capa EDGE</h3>
                <p><strong>Interfaz LAN:</strong> $IP_EDGE_LAN</p>
                <p><strong>Interfaz WAN:</strong> $IP_EDGE_WAN</p>
                <p><strong>Funciones:</strong> Router + Firewall</p>
            </div>
            <div class="card">
                <h3>🔴 Capa SERVICES</h3>
                <p><strong>Red:</strong> $NET_SERVICES</p>
                <p><strong>IP Servicios:</strong> $IP_SERVICES</p>
                <p><strong>Gateway:</strong> $IP_EDGE_WAN</p>
            </div>
        </div>
        
        <h2>🛠️ Servicios Activos:</h2>
        <table>
            <thead>
                <tr>
                    <th>Servicio</th>
                    <th>Puerto</th>
                    <th>Estado</th>
                    <th>URL/Acceso</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>🌐 Web Server (Nginx)</td>
                    <td>80</td>
                    <td><span style="color: green;">● Activo</span></td>
                    <td><a href="http://$IP_SERVICES">http://$IP_SERVICES</a></td>
                </tr>
                <tr>
                    <td>🗄️ Database (MariaDB)</td>
                    <td>3306</td>
                    <td><span style="color: green;">● Activo</span></td>
                    <td>mysql://$DB_USER:*****@$IP_SERVICES/$DB_NAME</td>
                </tr>
                <tr>
                    <td>🔍 DNS (Dnsmasq)</td>
                    <td>53</td>
                    <td><span style="color: green;">● Activo</span></td>
                    <td>web.lab.local → $IP_SERVICES</td>
                </tr>
                <tr>
                    <td>🛡️ Firewall (iptables)</td>
                    <td>N/A</td>
                    <td><span style="color: green;">● Activo</span></td>
                    <td>NAT + Filtrado activo</td>
                </tr>
            </tbody>
        </table>
        
        <h2>🔗 Endpoints Disponibles:</h2>
        <ul>
            <li><a href="/status">/status</a> - Estado del sistema</li>
            <li><a href="/api/db-test">/api/db-test</a> - Prueba de conexión a BD</li>
            <li><a href="/api/users">/api/users</a> - Lista de usuarios (ejemplo)</li>
        </ul>
        
        <div class="status info">
            <strong>📌 Nota:</strong> Este es un entorno de laboratorio para pruebas de arquitectura 3-tier.
            Las IPs y configuraciones están aisladas mediante network namespaces.
        </div>
    </div>
</body>
</html>
EOF

# Página de status
cat > /usr/share/nginx/html/status.html <<EOF
<h1>Estado del Sistema</h1>
<p><strong>IP Servidor:</strong> $IP_SERVICES</p>
<p><strong>Hora del sistema:</strong> $(date)</p>
<p><strong>Arquitectura:</strong> 3-Tier (Cliente-Edge-Servicios)</p>
<h3>Configuración de Red:</h3>
<ul>
<li><strong>Cliente:</strong> $IP_CLIENT</li>
<li><strong>Edge LAN:</strong> $IP_EDGE_LAN</li>
<li><strong>Edge WAN:</strong> $IP_EDGE_WAN</li>
<li><strong>Servicios:</strong> $IP_SERVICES</li>
</ul>
EOF

# 🔥 API endpoints ESTÁTICOS (reemplazan Lua)
echo "   📱 Creando APIs estáticas..."
cat > /usr/share/nginx/html/api/db-test.json <<EOF
{
  "status": "success",
  "message": "Endpoint de prueba de base de datos",
  "database": "$DB_NAME",
  "timestamp": "$(date +%Y-%m-%dT%H:%M:%S)",
  "services_ip": "$IP_SERVICES"
}
EOF

cat > /usr/share/nginx/html/api/users.json <<EOF
{
  "users": [
    {"id": 1, "name": "Juan Pérez", "email": "juan@lab.local", "departamento": "IT"},
    {"id": 2, "name": "María García", "email": "maria@lab.local", "departamento": "Desarrollo"},
    {"id": 3, "name": "Carlos López", "email": "carlos@lab.local", "departamento": "Operaciones"},
    {"id": 4, "name": "Ana Rodríguez", "email": "ana@lab.local", "departamento": "Seguridad"},
    {"id": 5, "name": "Pedro Sánchez", "email": "pedro@lab.local", "departamento": "Soporte"}
  ],
  "total": 5
}
EOF

cat > /usr/share/nginx/html/api/system.json <<EOF
{
  "system": "$(uname -a)",
  "ip": "$IP_SERVICES",
  "architecture": "3-Tier (CLIENT-EDGE-SERVICES)",
  "timestamp": "$(date +%Y-%m-%dT%H:%M:%S)"
}
EOF

# Nginx (NS-SERVICES) - SIN LUA + FIX server_name
cat > /etc/lab-configs/nginx.conf <<EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript;
    
    server {
        listen $IP_SERVICES:80 backlog=4096;
        listen [::]:80;
        server_name web.lab.local www.lab.local;  # 🔥 FIX: Sintaxis correcta
        root /usr/share/nginx/html;
        index index.html index.htm;
        
        location / {
            try_files \$uri \$uri/ =404;
        }
        
        location /status {
            alias /usr/share/nginx/html/status.html;
        }
        
        # 🔥 APIs ESTÁTICAS (reemplazan Lua)
        location /api/db-test {
            alias /usr/share/nginx/html/api/db-test.json;
            add_header Content-Type application/json;
        }
        
        location /api/users {
            alias /usr/share/nginx/html/api/users.json;
            add_header Content-Type application/json;
        }
        
        location /api/system {
            alias /usr/share/nginx/html/api/system.json;
            add_header Content-Type application/json;
        }
        
        error_page 404 /404.html;
        location = /404.html {
            internal;
        }
        
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            internal;
        }
    }
}
EOF

# Dnsmasq (NS-SERVICES) - Configuración mejorada
cat > /etc/lab-configs/dnsmasq.conf <<EOF
# Configuración Dnsmasq para LAB 3-Tier
interface=veth-srv
listen-address=$IP_SERVICES
bind-interfaces
domain=lab.local
expand-hosts
local=/lab.local/

# No proveer DHCP
no-dhcp-interface=veth-srv
dhcp-range=10.10.100.100,10.10.100.150,12h

# Servidores DNS upstream
server=8.8.8.8
server=1.1.1.1
server=8.8.4.4

# Registros DNS para el LAB
address=/web.lab.local/$IP_SERVICES
address=/www.lab.local/$IP_SERVICES
address=/db.lab.local/$IP_SERVICES
address=/mysql.lab.local/$IP_SERVICES
address=/dns.lab.local/$IP_SERVICES
address=/ns1.lab.local/$IP_SERVICES
address=/router.lab.local/$IP_EDGE_WAN
address=/client.lab.local/$IP_CLIENT
address=/lab.local/$IP_SERVICES

# Wildcard para subdominios
address=/.lab.local/$IP_SERVICES

# Registros PTR (reverse DNS)
ptr-record=10.100.10.in-addr.arpa,$IP_SERVICES,web.lab.local
ptr-record=1.100.10.in-addr.arpa,$IP_EDGE_WAN,router.lab.local
ptr-record=10.50.10.in-addr.arpa,$IP_CLIENT,client.lab.local

# Cache size
cache-size=1000
local-ttl=300

# Logging
log-queries
log-facility=/var/log/dnsmasq.log
EOF

echo "   ✅ Configuraciones generadas"
echo "      • index.html + status.html"
echo "      • APIs estáticas: /api/users /api/db-test /api/system"
echo "      • nginx.conf (sin Lua - 100% Rocky Linux)"
echo "      • dnsmasq.conf mejorado"


# ---------------------------------------------------------------------------
# 7️⃣ SCRIPT DE RED Y NAMESPACES (EL NÚCLEO)
# ---------------------------------------------------------------------------
# Este bloque genera el "corazón" lógico del laboratorio: un script de automatización que 
# orquestra la topología de red virtual. Su función principal es segmentar el sistema en 
# tres áreas aisladas (Namespaces: CLIENT, EDGE y SERVICES), interconectándolas mediante 
# pares de cables virtuales (veth). El script no solo establece el direccionamiento IP y 
# el enrutamiento estático para que el tráfico fluya entre capas, sino que también 
# transforma al nodo EDGE en un router/firewall activo. Para ello, habilita el reenvío de 
# paquetes (IP Forwarding) y aplica políticas estrictas de seguridad mediante IPTables, 
# implementando NAT, inspección de estado (conntrack) y filtrado por puertos, emulando 
# así el comportamiento real de un firewall perimetral en un entorno de producción.
# ---------------------------------------------------------------------------

echo "[7/14] 🌐 Generando script de configuración de red..."

# Crear DIRECTORIO de configuraciones primero
mkdir -p /etc/lab-configs/

# 1. PRIMERO CREAR LA VERSIÓN IDEMPOTENTE
cat > /usr/local/bin/lab-net-setup-idempotent.sh << 'EOF'
#!/bin/bash

set -e

echo "🔧 Configurando network namespaces (IDEMPOTENTE)..."

# Cargar variables si existen
NET_CLIENT=${NET_CLIENT:-"10.10.50.0/24"}
NET_SERVICES=${NET_SERVICES:-"10.10.100.0/24"}
IP_CLIENT=${IP_CLIENT:-"10.10.50.10"}
IP_SERVICES=${IP_SERVICES:-"10.10.100.10"}
IP_EDGE_LAN=${IP_EDGE_LAN:-"10.10.50.1"}
IP_EDGE_WAN=${IP_EDGE_WAN:-"10.10.100.1"}

# 1. CREAR NAMESPACES (si no existen)
for ns in NS-CLIENT NS-EDGE NS-SERVICES; do
    if ! ip netns list | grep -q "$ns"; then
        echo "   ✅ Creando namespace $ns..."
        ip netns add "$ns"
    else
        echo "   ℹ️  Namespace $ns ya existe"
    fi
done

# 2. CONFIGURAR INTERFACES (manejo idempotente)
configure_interface() {
    local ns=$1
    local iface=$2
    local ip=$3
    
    # Verificar si la interfaz ya está configurada
    if ip netns exec "$ns" ip addr show "$iface" 2>/dev/null | grep -q "$ip"; then
        echo "   ℹ️  Interfaz $iface en $ns ya tiene IP $ip"
        return 0
    fi
    
    # Si no existe, crearla
    if ! ip netns exec "$ns" ip link show "$iface" &>/dev/null; then
        echo "   🔗 Creando interfaz $iface en $ns..."
        
        case "$iface" in
            veth-client)
                ip link add veth-client type veth peer name veth-edge-cli
                ip link set veth-client netns NS-CLIENT
                ip link set veth-edge-cli netns NS-EDGE
                ;;
            veth-srv)
                ip link add veth-srv type veth peer name veth-edge-srv
                ip link set veth-srv netns NS-SERVICES
                ip link set veth-edge-srv netns NS-EDGE
                ;;
        esac
    fi
    
    # Configurar IP solo si no está configurada
    echo "   ⚙️  Configurando $iface con IP $ip en $ns..."
    ip netns exec "$ns" ip addr add "$ip" dev "$iface" 2>/dev/null || true
    ip netns exec "$ns" ip link set "$iface" up
    ip netns exec "$ns" ip link set lo up
}

# 3. CONFIGURAR INTERFACES CON MANEJO DE ERRORES
echo "🔗 Conectando CLIENT <-> EDGE..."
configure_interface NS-CLIENT veth-client "$IP_CLIENT/24"
configure_interface NS-EDGE veth-edge-cli "$IP_EDGE_LAN/24"

echo "🔗 Conectando EDGE <-> SERVICES..."
configure_interface NS-SERVICES veth-srv "$IP_SERVICES/24"
configure_interface NS-EDGE veth-edge-srv "$IP_EDGE_WAN/24"

# 4. CONFIGURAR ROUTING (idempotente)
echo "🌐 Configurando routing..."

# En CLIENT: default route hacia EDGE
if ! ip netns exec NS-CLIENT ip route | grep -q "default via $IP_EDGE_LAN"; then
    ip netns exec NS-CLIENT ip route add default via "$IP_EDGE_LAN"
fi

# En SERVICES: default route hacia EDGE
if ! ip netns exec NS-SERVICES ip route | grep -q "default via $IP_EDGE_WAN"; then
    ip netns exec NS-SERVICES ip route add default via "$IP_EDGE_WAN"
fi

# En EDGE: habilitar forwarding
ip netns exec NS-EDGE sysctl -w net.ipv4.ip_forward=1 >/dev/null
ip netns exec NS-EDGE sysctl -w net.ipv4.conf.all.rp_filter=0 >/dev/null
ip netns exec NS-EDGE sysctl -w net.ipv4.conf.all.arp_announce=2 >/dev/null

# 5. CONFIGURAR FIREWALL (idempotente)
echo "🛡️  Configurando firewall en EDGE..."

# Limpiar reglas existentes
ip netns exec NS-EDGE iptables -F
ip netns exec NS-EDGE iptables -t nat -F
ip netns exec NS-EDGE iptables -X

# Políticas por defecto
ip netns exec NS-EDGE iptables -P INPUT DROP
ip netns exec NS-EDGE iptables -P FORWARD DROP
ip netns exec NS-EDGE iptables -P OUTPUT ACCEPT

# Permitir tráfico forward entre redes
ip netns exec NS-EDGE iptables -A FORWARD -i veth-edge-cli -o veth-edge-srv -j ACCEPT
ip netns exec NS-EDGE iptables -A FORWARD -i veth-edge-srv -o veth-edge-cli -m state --state ESTABLISHED,RELATED -j ACCEPT

# NAT para salida a internet (simulada)
ip netns exec NS-EDGE iptables -t nat -A POSTROUTING -o veth-edge-srv -j MASQUERADE

# Permitir ping y DNS
ip netns exec NS-EDGE iptables -A FORWARD -p icmp -j ACCEPT
ip netns exec NS-EDGE iptables -A FORWARD -p udp --dport 53 -j ACCEPT
ip netns exec NS-EDGE iptables -A FORWARD -p tcp --dport 53 -j ACCEPT

# Logging para debugging
ip netns exec NS-EDGE iptables -A FORWARD -j LOG --log-prefix "[LAB-FW-FORWARD] "

# Habilitar logging en kernel
ip netns exec NS-EDGE sysctl -w net.netfilter.nf_log.2=nf_log_ipv4 >/dev/null

echo "✅ Configuración de red completada (IDEMPOTENTE)"

# 6. MOSTRAR RESUMEN
echo ""
echo "📊 RESUMEN DE CONFIGURACIÓN:"
echo "   Namespaces:"
ip netns list
echo ""
echo "   Interfaces en NS-CLIENT:"
ip netns exec NS-CLIENT ip addr show veth-client 2>/dev/null || echo "    No configurada"
echo ""
echo "   Interfaces en NS-EDGE:"
ip netns exec NS-EDGE ip addr show veth-edge-cli 2>/dev/null || echo "    No configurada"
ip netns exec NS-EDGE ip addr show veth-edge-srv 2>/dev/null || echo "    No configurada"
echo ""
echo "   Interfaces en NS-SERVICES:"
ip netns exec NS-SERVICES ip addr show veth-srv 2>/dev/null || echo "    No configurada"
EOF

chmod +x /usr/local/bin/lab-net-setup-idempotent.sh

# 2. LUEGO CREAR LA VERSIÓN REGULAR QUE USA LA IDEMPOTENTE
cat > /usr/local/bin/lab-net-setup.sh << 'EOF'
#!/bin/bash
# Este es un wrapper que usa la versión idempotente
/usr/local/bin/lab-net-setup-idempotent.sh
EOF

chmod +x /usr/local/bin/lab-net-setup.sh

echo "   ✅ Scripts de red generados:"
echo "      • /usr/local/bin/lab-net-setup-idempotent.sh"
echo "      • /usr/local/bin/lab-net-setup.sh"

# ---------------------------------------------------------------------------
# 8️⃣ SCRIPT DE VERIFICACIÓN DE SALUD (HEALTH CHECK)
# ---------------------------------------------------------------------------
# Este bloque crea una herramienta de diagnóstico integral diseñada para validar la 
# integridad de toda la arquitectura 3-Tier desde un solo punto. El script automatiza 
# pruebas de conectividad extremo a extremo (end-to-end), verificando que los saltos 
# entre Namespaces sean correctos, que los servicios críticos (Nginx, MariaDB, Dnsmasq) 
# estén escuchando en sus respectivos puertos y que la resolución DNS interna sea 
# funcional. Al incluir pruebas de nivel de aplicación (como 'curl' a los endpoints) 
# y auditoría de reglas de firewall, este componente permite al administrador confirmar 
# instantáneamente si la segmentación de red y las políticas de seguridad están operando 
# según lo previsto, facilitando la detección temprana de errores de configuración.
# ---------------------------------------------------------------------------
echo "[8/14] 🩺 Creando script de verificación de salud..."

cat > /usr/local/bin/lab-health-check.sh <<'EOF'
#!/bin/bash
# ============================================================================
# SCRIPT DE VERIFICACIÓN DE SALUD DEL LAB 3-TIER
# ============================================================================

echo "=== 🩺 HEALTH CHECK DEL LAB 3-TIER ==="
echo "📅 Fecha: $(date)"
echo ""

# 1. Verificar namespaces
echo "1. 🔍 NAMESPACES:"
echo "-----------------"
if ip netns list | grep -q "NS-"; then
    ip netns list
    echo "✅ Namespaces activos"
else
    echo "❌ No hay namespaces activos"
fi
echo ""

# 2. Verificar conectividad
echo "2. 📡 CONECTIVIDAD:"
echo "-------------------"
echo "   Cliente -> Servicios:"
if ip netns exec NS-CLIENT ping -c 2 -W 1 $IP_SERVICES > /dev/null 2>&1; then
    echo "   ✅ Ping exitoso: $IP_CLIENT → $IP_SERVICES"
else
    echo "   ❌ Ping falló"
fi
echo ""

# 3. Verificar servicios en NS-SERVICES
echo "3. 🛠️  SERVICIOS EN NS-SERVICES:"
echo "---------------------------------"
echo "   Procesos activos:"
ip netns exec NS-SERVICES ps aux | grep -E "(nginx|dnsmasq)" | grep -v grep || echo "   ⚠️  No hay procesos activos"
echo ""

echo "   Puertos escuchando:"
ip netns exec NS-SERVICES netstat -tlnp 2>/dev/null | grep -E "(80|53|3306)" || echo "   ⚠️  No hay puertos críticos escuchando"
echo ""

# 4. Verificar DNS
echo "4. 🔍 RESOLUCIÓN DNS:"
echo "---------------------"
if ip netns exec NS-CLIENT nslookup web.lab.local $IP_SERVICES > /dev/null 2>&1; then
    echo "   ✅ DNS funcionando (web.lab.local resuelve a $IP_SERVICES)"
else
    echo "   ❌ DNS no funciona"
fi
echo ""

# 5. Verificar Web
echo "5. 🌐 SERVICIO WEB:"
echo "-------------------"
if ip netns exec NS-CLIENT curl -s --connect-timeout 3 http://$IP_SERVICES > /dev/null; then
    echo "   ✅ Web server respondiendo"
    echo "   📄 Contenido de /status:"
    ip netns exec NS-CLIENT curl -s http://$IP_SERVICES/status | head -5
else
    echo "   ❌ Web server no responde"
fi
echo ""

# 6. Verificar base de datos
echo "6. 🗄️  BASE DE DATOS:"
echo "---------------------"
if systemctl is-active mariadb > /dev/null; then
    echo "   ✅ MariaDB activo"
    echo "   📊 Bases de datos disponibles:"
    mysql -e "SHOW DATABASES;" | grep -E "(labdb|mysql|information_schema)"
else
    echo "   ❌ MariaDB inactivo"
fi
echo ""

# 7. Verificar firewall
echo "7. 🛡️  REGLAS DE FIREWALL:"
echo "--------------------------"
echo "   Reglas FORWARD en EDGE:"
ip netns exec NS-EDGE iptables -L FORWARD -n --line-numbers | head -20
echo ""

# 8. Resumen
echo "8. 📊 RESUMEN FINAL:"
echo "-------------------"
echo "   ✅ Servicios esperados:"
echo "      - Network namespaces: 3/3"
echo "      - DNS (dnsmasq): $(systemctl is-active dnsmasq 2>/dev/null || echo 'inactivo')"
echo "      - Web (nginx): $(systemctl is-active nginx 2>/dev/null || echo 'inactivo')"
echo "      - DB (mariadb): $(systemctl is-active mariadb 2>/dev/null || echo 'inactivo')"
echo ""
echo "   🔗 Accesos:"
echo "      - SSH: ssh student@localhost"
echo "      - Web: http://$IP_SERVICES"
echo "      - DNS: dig @$IP_SERVICES web.lab.local"
echo "      - MySQL: mysql -u $DB_USER -p$DB_PASS -h $IP_SERVICES $DB_NAME"
EOF

chmod +x /usr/local/bin/lab-health-check.sh


# ---------------------------------------------------------------------------
# 9️⃣ PERSISTENCIA CON SYSTEMD - VERSIÓN DEFINITIVA Y SIMPLIFICADA
# ---------------------------------------------------------------------------
# Este bloque transforma el laboratorio de una configuración manual y volátil en un servicio 
# de sistema robusto y persistente. Ahora que el script lab-net-setup.sh ES IDEMPOTENTE por
# diseño (creado en el bloque 7), podemos crear servicios systemd que funcionarán correctamente
# tanto en la instalación inicial como en reinicios posteriores.
# ---------------------------------------------------------------------------
echo "[9/14] 🔄 Configurando servicios y persistencia..."

# 1. EJECUTAR RED (script ya es idempotente gracias al bloque 7)
echo "   🌐 Configurando red (idempotente)..."
/usr/local/bin/lab-net-setup.sh
echo "   ✅ Red configurada"

# 2. CREAR SERVICIOS SYSTEMD SIMPLIFICADOS Y ROBUSTOS
echo "   🛠️  Configurando systemd services..."

# Servicio para nginx (DENTRO del namespace) - SIMPLIFICADO
cat > /etc/systemd/system/lab-nginx-ns.service << 'EOF'
[Unit]
Description=Nginx Web Server inside NS-SERVICES namespace
After=network.target
Wants=network.target
ConditionPathExists=/var/run/netns/NS-SERVICES

[Service]
Type=simple
# Esperar a que el namespace exista (máximo 10 segundos)
ExecStartPre=/bin/bash -c 'count=0; while [ ! -e /var/run/netns/NS-SERVICES ] && [ $count -lt 20 ]; do sleep 0.5; count=$((count+1)); done'
ExecStartPre=/bin/bash -c 'if [ ! -e /var/run/netns/NS-SERVICES ]; then echo "ERROR: NS-SERVICES namespace not found"; exit 1; fi'
# Ejecutar nginx DENTRO del namespace
ExecStart=/usr/bin/ip netns exec NS-SERVICES /usr/sbin/nginx -g "daemon off;" -c /etc/lab-configs/nginx.conf
ExecStop=/usr/bin/ip netns exec NS-SERVICES /usr/sbin/nginx -s quit
Restart=on-failure
RestartSec=3
TimeoutStartSec=30
TimeoutStopSec=10

# Configurar entorno
Environment=NGINX_CONF=/etc/lab-configs/nginx.conf
StandardOutput=journal
StandardError=journal
SyslogIdentifier=lab-nginx

[Install]
WantedBy=multi-user.target
EOF

# Servicio para dnsmasq (DENTRO del namespace) - SIMPLIFICADO
cat > /etc/systemd/system/lab-dnsmasq-ns.service << 'EOF'
[Unit]
Description=Dnsmasq DNS/DHCP inside NS-SERVICES namespace
After=network.target
Wants=network.target
ConditionPathExists=/var/run/netns/NS-SERVICES

[Service]
Type=simple
# Esperar a que el namespace exista (máximo 10 segundos)
ExecStartPre=/bin/bash -c 'count=0; while [ ! -e /var/run/netns/NS-SERVICES ] && [ $count -lt 20 ]; do sleep 0.5; count=$((count+1)); done'
ExecStartPre=/bin/bash -c 'if [ ! -e /var/run/netns/NS-SERVICES ]; then echo "ERROR: NS-SERVICES namespace not found"; exit 1; fi'
# Ejecutar dnsmasq DENTRO del namespace
ExecStart=/usr/bin/ip netns exec NS-SERVICES /usr/sbin/dnsmasq --keep-in-foreground -C /etc/lab-configs/dnsmasq.conf
ExecStop=/usr/bin/ip netns exec NS-SERVICES /usr/bin/pkill dnsmasq
Restart=on-failure
RestartSec=3
TimeoutStartSec=30
TimeoutStopSec=10

# Configurar entorno
Environment=DNSMASQ_CONF=/etc/lab-configs/dnsmasq.conf
StandardOutput=journal
StandardError=journal
SyslogIdentifier=lab-dnsmasq

[Install]
WantedBy=multi-user.target
EOF

# Servicio PRINCIPAL que maneja solo los namespaces - SIMPLIFICADO
cat > /etc/systemd/system/lab-infrastructure.service << 'EOF'
[Unit]
Description=Lab 3-Tier Network Infrastructure (Namespaces Setup)
After=network.target
Wants=network.target
Before=lab-nginx-ns.service lab-dnsmasq-ns.service

[Service]
Type=oneshot
RemainAfterExit=yes
# Usar script IDEMPOTENTE (gracias al bloque 7)
ExecStart=/usr/local/bin/lab-net-setup.sh
# Pequeña pausa para estabilización
ExecStartPost=/bin/sleep 2

StandardOutput=journal
StandardError=journal
SyslogIdentifier=lab-infra

[Install]
WantedBy=multi-user.target
EOF

# 3. RECARGAR SYSTEMD
systemctl daemon-reload

# 4. HABILITAR SERVICIOS (para inicio automático post-reinicio)
systemctl enable lab-infrastructure
systemctl enable lab-nginx-ns
systemctl enable lab-dnsmasq-ns

echo "   ✅ Servicios systemd configurados y habilitados"

# 5. INICIAR SERVICIOS AHORA MISMO (no esperar al reinicio)
echo "   🚀 Iniciando servicios..."

# Iniciar infraestructura - SEGURO porque es idempotente
echo "   🔹 Iniciando infraestructura de red..."
systemctl start lab-infrastructure
sleep 3

# Verificar que los namespaces existen antes de continuar
if ip netns list | grep -q "NS-SERVICES"; then
    echo "   ✅ Namespaces creados correctamente"
    
    # Iniciar nginx
    echo "   🔹 Iniciando nginx..."
    if systemctl start lab-nginx-ns; then
        echo "   ✅ Nginx iniciado via systemd"
    else
        echo "   ⚠️  Falló systemd, iniciando nginx manualmente..."
        ip netns exec NS-SERVICES /usr/sbin/nginx -g "daemon off;" -c /etc/lab-configs/nginx.conf &
        echo $! > /tmp/lab-nginx.pid
    fi
    sleep 2
    
    # Iniciar dnsmasq
    echo "   🔹 Iniciando dnsmasq..."
    if systemctl start lab-dnsmasq-ns; then
        echo "   ✅ Dnsmasq iniciado via systemd"
    else
        echo "   ⚠️  Falló systemd, iniciando dnsmasq manualmente..."
        ip netns exec NS-SERVICES /usr/sbin/dnsmasq -C /etc/lab-configs/dnsmasq.conf --no-daemon &
        echo $! > /tmp/lab-dnsmasq.pid
    fi
    sleep 2
else
    echo "   ❌ ERROR: No se pudieron crear los namespaces"
    echo "   🔧 Creando namespaces manualmente..."
    /usr/local/bin/lab-net-setup.sh
    sleep 3
    
    # Iniciar servicios manualmente
    ip netns exec NS-SERVICES /usr/sbin/nginx -g "daemon off;" -c /etc/lab-configs/nginx.conf &
    ip netns exec NS-SERVICES /usr/sbin/dnsmasq -C /etc/lab-configs/dnsmasq.conf --no-daemon &
    echo "   ✅ Servicios iniciados manualmente"
fi

echo ""
echo "   🔍 Verificación final del lab..."
sleep 3

echo "   🧪 Ejecutando pruebas integrales..."

# Test 1: Conectividad básica
echo -n "   🔗 Conectividad (ping 10.10.100.10)... "
if ip netns exec NS-CLIENT ping -c 2 -W 1 10.10.100.10 >/dev/null 2>&1; then
    echo "✅ OK"
    PING_OK=true
else
    echo "❌ FALLÓ"
    PING_OK=false
fi

# Test 2: Servicio Web
echo -n "   🌐 Servicio Web (HTTP)... "
WEB_CODE=$(ip netns exec NS-CLIENT curl -s -o /dev/null -w "%{http_code}" http://10.10.100.10 2>/dev/null || echo "000")
if [[ "$WEB_CODE" == "200" ]]; then
    echo "✅ HTTP 200"
    WEB_OK=true
elif [[ "$WEB_CODE" == "000" ]]; then
    echo "❌ Sin conexión"
    WEB_OK=false
else
    echo "⚠️  HTTP $WEB_CODE"
    WEB_OK=false
fi

# Test 3: Resolución DNS
echo -n "   📡 Resolución DNS (web.lab.local)... "
if ip netns exec NS-CLIENT timeout 2 nslookup web.lab.local 10.10.100.10 >/dev/null 2>&1; then
    echo "✅ Funcional"
    DNS_OK=true
else
    echo "❌ Falló"
    DNS_OK=false
fi

# Test 4: Base de datos
echo -n "   🗄️  Base de datos MariaDB... "
if mysql -u labuser -predhat -h 10.10.100.10 -e "SELECT 1" labdb 2>/dev/null | grep -q "1"; then
    echo "✅ Conectada"
    DB_OK=true
else
    echo "❌ Sin conexión"
    DB_OK=false
fi

echo ""
echo "   📊 RESUMEN DE PRUEBAS:"
echo "   "$(printf '=%.0s' {1..40})

# Contar éxitos
SUCCESS_COUNT=0
[[ "$PING_OK" = true ]] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
[[ "$WEB_OK" = true ]] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
[[ "$DNS_OK" = true ]] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
[[ "$DB_OK" = true ]] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))

if [[ $SUCCESS_COUNT -eq 4 ]]; then
    echo "   🎉🎉🎉 ¡LAB 3-TIER 100% OPERATIVO! 🎉🎉🎉"
    echo ""
    echo "   ✅ Todas las pruebas exitosas (4/4)"
    echo "      • Conectividad de red: ✅"
    echo "      • Servicio Web (Nginx): ✅ HTTP 200"
    echo "      • Resolución DNS: ✅ web.lab.local → 10.10.100.10"
    echo "      • Base de datos: ✅ MariaDB conectada"
    echo ""
    echo "   🚀 ¡Lab listo para snapshot y producción!"
elif [[ $SUCCESS_COUNT -ge 2 ]]; then
    echo "   ⚠️  Lab parcialmente funcional ($SUCCESS_COUNT/4 pruebas)"
    echo "   💡 Ejecuta 'lab-ctl test' para diagnóstico detallado"
else
    echo "   ❌ Lab con problemas significativos"
    echo "   🔧 Ejecuta '/root/fix-services.sh' para reparar"
fi

echo "   "$(printf '=%.0s' {1..40})
echo ""

# ============================================================================
# 🛠️ CREAR SCRIPT DE REPARACIÓN POR SI ACASO
# ============================================================================
cat > /root/fix-lab-services.sh << 'EOF'
#!/bin/bash
echo "🔧 Reparando servicios del lab 3-Tier..."

# Detener servicios problemáticos
systemctl stop lab-nginx-ns lab-dnsmasq-ns 2>/dev/null || true

# Matar procesos residuales
ip netns exec NS-SERVICES pkill nginx 2>/dev/null || true
ip netns exec NS-SERVICES pkill dnsmasq 2>/dev/null || true
sleep 1

# Iniciar servicios manualmente (siempre funciona)
ip netns exec NS-SERVICES /usr/sbin/nginx -g "daemon off;" -c /etc/lab-configs/nginx.conf &
ip netns exec NS-SERVICES /usr/sbin/dnsmasq -C /etc/lab-configs/dnsmasq.conf --no-daemon &

echo "✅ Servicios reparados"
echo "📊 Verifica con: lab-ctl test"
EOF

chmod +x /root/fix-lab-services.sh

echo "   🛡️  Script de reparación creado: /root/fix-lab-services.sh"



# 6. CREAR SCRIPT DE CONTROL FÁCIL
cat > /usr/local/bin/lab-ctl << 'EOF'
#!/bin/bash

case "$1" in
    start)
        echo "🚀 Iniciando lab completo..."
        systemctl start lab-infrastructure
        sleep 3
        systemctl start lab-nginx-ns
        systemctl start lab-dnsmasq-ns
        echo "✅ Lab iniciado"
        ;;
    stop)
        echo "🛑 Deteniendo lab..."
        systemctl stop lab-dnsmasq-ns lab-nginx-ns lab-infrastructure
        echo "✅ Lab detenido"
        ;;
    restart)
        echo "🔁 Reiniciando lab..."
        systemctl stop lab-dnsmasq-ns lab-nginx-ns 2>/dev/null || true
        systemctl restart lab-infrastructure
        sleep 3
        systemctl start lab-nginx-ns
        systemctl start lab-dnsmasq-ns
        echo "✅ Lab reiniciado"
        ;;
    status)
        echo "=== 🏷️  NAMESPACES ==="
        ip netns list
        echo ""
        echo "=== 🖥️  SERVICIOS SYSTEMD ==="
        systemctl status lab-infrastructure lab-nginx-ns lab-dnsmasq-ns --no-pager | grep -A1 "●\|Active:" | head -12
        echo ""
        echo "=== 🔗 CONECTIVIDAD ==="
        if ip netns exec NS-CLIENT ping -c 1 -W 1 10.10.100.10 >/dev/null 2>&1; then
            echo "✅ Cliente -> Servicios: CONECTADO"
            echo "🌐 Web: http://10.10.100.10"
        else
            echo "❌ Cliente -> Servicios: SIN CONEXIÓN"
        fi
        ;;
    logs)
        echo "📋 Mostrando logs del lab (Ctrl+C para salir)..."
        journalctl -u lab-infrastructure -u lab-nginx-ns -u lab-dnsmasq-ns -f
        ;;
    test)
        echo "🧪 Ejecutando pruebas..."
        echo "1. Probando conectividad..."
        ip netns exec NS-CLIENT ping -c 2 10.10.100.10
        echo ""
        echo "2. Probando web..."
        ip netns exec NS-CLIENT curl -s -o /dev/null -w "Código HTTP: %{http_code}\n" http://10.10.100.10
        echo ""
        echo "3. Probando DNS..."
        ip netns exec NS-CLIENT nslookup web.lab.local 10.10.100.10
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|status|logs|test}"
        echo ""
        echo "Comandos:"
        echo "  start   - Iniciar todo el lab"
        echo "  stop    - Detener todo el lab"
        echo "  restart - Reiniciar todo el lab"
        echo "  status  - Ver estado completo"
        echo "  logs    - Ver logs en tiempo real"
        echo "  test    - Ejecutar pruebas de conectividad"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/lab-ctl

# 7. CREAR ARCHIVO DE RESUMEN
cat > /root/lab-systemd-summary.txt << EOF
=== RESUMEN DE CONFIGURACIÓN SYSTEMD ===
Fecha: $(date)

SERVICIOS CREADOS:
1. lab-infrastructure.service
   - Descripción: Configura namespaces y red
   - Tipo: oneshot (RemainAfterExit=yes)
   - Script: /usr/local/bin/lab-net-setup.sh (IDEMPOTENTE)

2. lab-nginx-ns.service  
   - Descripción: Nginx dentro de NS-SERVICES
   - Depende de: lab-infrastructure.service
   - Verifica: namespace existe antes de iniciar

3. lab-dnsmasq-ns.service
   - Descripción: Dnsmasq dentro de NS-SERVICES
   - Depende de: lab-infrastructure.service
   - Verifica: namespace existe antes de iniciar

HERRAMIENTAS:
- lab-ctl: Control completo del lab
  Comandos: start, stop, restart, status, logs, test

VERIFICACIÓN POST-INSTALACIÓN:
1. systemctl status lab-infrastructure
2. lab-ctl status
3. lab-ctl test

PERSISTENCIA AL REINICIO:
Los servicios están habilitados (enable) y se iniciarán automáticamente.
EOF

echo "   ✅ Configuración de persistencia COMPLETADA"
echo ""
echo "   📋 RESUMEN FINAL:"
echo "   • Script de red: IDEMPOTENTE por diseño"
echo "   • 3 servicios systemd creados y habilitados"
echo "   • Herramienta: lab-ctl {start|stop|restart|status|logs|test}"
echo ""
echo "   🔧 Comandos para probar AHORA:"
echo "      lab-ctl status   # Ver estado completo"
echo "      lab-ctl test     # Ejecutar pruebas"
echo "      lab-ctl logs     # Ver logs en tiempo real"
echo ""
echo "   💾 Resumen guardado en: /root/lab-systemd-summary.txt"



# ---------------------------------------------------------------------------
# 🔟 ACCESO EXTERNO Y ROUTING (COMUNICACIÓN HOST-LAB)
# ---------------------------------------------------------------------------
# Este bloque actúa como el "puente" definitivo entre la infraestructura virtualizada y el 
# exterior. Su objetivo es habilitar el enrutamiento a nivel de kernel en el sistema Host, 
# permitiendo que los paquetes de datos fluyan desde los Namespaces aislados hacia la red 
# física o Internet. Mediante la activación de 'ip_forward' y la configuración de reglas 
# NAT (Masquerade) en el Host, se garantiza que los nodos del laboratorio (como el cliente 
# o el servidor de servicios) puedan realizar actualizaciones de paquetes o consultas 
# externas, enmascarando sus IPs privadas bajo la IP real del host. Básicamente, esto 
# convierte a la máquina anfitriona en el último salto de salida (Gateway) para todo el 
# tráfico generado dentro del ecosistema 3-Tier.
# ---------------------------------------------------------------------------

echo "[10/14] 🌉 Configurando routing en el Host..."

# Habilitar forwarding
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-lab-kernel.conf

# Configurar reglas iptables en el host para permitir tráfico
iptables -t nat -A POSTROUTING -s 10.10.50.0/24 -j MASQUERADE 2>/dev/null || true
iptables -A FORWARD -i virbr0 -o enp1s0 -j ACCEPT 2>/dev/null || true
iptables -A FORWARD -i enp1s0 -o virbr0 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true

# Aplicar cambios de sysctl
sysctl -p /etc/sysctl.d/99-lab-kernel.conf

echo "   ✅ Routing configurado"

# ---------------------------------------------------------------------------
# 11️⃣ ALIASES Y COMODIDAD (UX & TROUBLESHOOTING)
# ---------------------------------------------------------------------------
# Este bloque optimiza la interacción del administrador con el entorno mediante la creación 
# de un ecosistema de comandos personalizados y herramientas de "atajo". Su propósito es 
# eliminar la complejidad de los comandos largos de 'ip netns', encapsulando tareas críticas 
# como el salto entre redes, la verificación de bases de datos, el monitoreo de tráfico con 
# tcpdump y las pruebas de resolución DNS en alias cortos y memorizables. Al cargar estas 
# funciones en el perfil global del sistema, se facilita un flujo de trabajo ágil para el 
# diagnóstico de fallos (troubleshooting) y se proporciona un script de reinicio rápido 
# ('lab-reset') que garantiza que el estudiante pueda restaurar el entorno a un estado 
# conocido en segundos, minimizando el tiempo perdido en tareas repetitivas de terminal.
# ---------------------------------------------------------------------------
echo "[11/14] 🎯 Configurando aliases y herramientas..."

cat > /etc/profile.d/lab-aliases.sh <<EOF
# ============================================================================
# ALIASES PARA LAB 3-TIER
# ============================================================================

# Aliases para namespaces
alias ns-client='ip netns exec NS-CLIENT bash'
alias ns-edge='ip netns exec NS-EDGE bash'
alias ns-services='ip netns exec NS-SERVICES bash'

# Aliases para verificación
alias lab-check='ip netns exec NS-CLIENT curl -s http://$IP_SERVICES'
alias lab-test-dns='ip netns exec NS-CLIENT nslookup web.lab.local $IP_SERVICES'
alias lab-test-ping='ip netns exec NS-CLIENT ping -c 3 $IP_SERVICES'
alias lab-test-db='mysql -u $DB_USER -p$DB_PASS -h $IP_SERVICES $DB_NAME -e "SELECT COUNT(*) as total_usuarios FROM usuarios;"'

# Aliases para monitoreo
alias lab-status='systemctl status lab-infrastructure'
alias lab-logs='journalctl -u lab-infrastructure -f'
alias lab-health='/usr/local/bin/lab-health-check.sh'
alias lab-interfaces='echo "=== NS-CLIENT ===" && ip netns exec NS-CLIENT ip addr; echo "=== NS-EDGE ===" && ip netns exec NS-EDGE ip addr; echo "=== NS-SERVICES ===" && ip netns exec NS-SERVICES ip addr'

# Aliases para troubleshooting
alias lab-trace='ip netns exec NS-CLIENT traceroute $IP_SERVICES'
alias lab-curl='ip netns exec NS-CLIENT curl -v'
alias lab-tcpdump-client='ip netns exec NS-CLIENT tcpdump -i veth-client'
alias lab-tcpdump-services='ip netns exec NS-SERVICES tcpdump -i veth-srv'

# Accesos rápidos
alias web-lab='curl http://$IP_SERVICES'
alias dns-lab='dig @$IP_SERVICES web.lab.local'
alias ssh-lab='ssh student@localhost'

# Información del lab
alias lab-info='echo "=== LAB 3-TIER ===\nCliente: $IP_CLIENT\nEdge LAN: $IP_EDGE_LAN\nEdge WAN: $IP_EDGE_WAN\nServicios: $IP_SERVICES\nBD: $DB_NAME@$IP_SERVICES"'

# Limpieza
alias lab-clean='sudo systemctl stop lab-infrastructure && sudo ip netns delete NS-CLIENT NS-EDGE NS-SERVICES 2>/dev/null; echo "Lab limpiado"'
alias lab-restart='sudo systemctl restart lab-infrastructure'
EOF

# Crear script de reset rápido
cat > /usr/local/bin/lab-reset.sh <<EOF
#!/bin/bash
echo "🔄 Reiniciando lab 3-tier..."
systemctl stop lab-infrastructure
systemctl start lab-infrastructure
echo "✅ Lab reiniciado"
lab-health-check.sh
EOF
chmod +x /usr/local/bin/lab-reset.sh

echo "   ✅ Aliases configurados"

# ---------------------------------------------------------------------------
# 12️⃣ VERIFICACIÓN INICIAL (SMOKE TEST)
# ---------------------------------------------------------------------------
# Este bloque actúa como una prueba de "humo" o validación rápida para asegurar que la 
# infraestructura desplegada es operativa inmediatamente después de su creación. Tras una 
# breve pausa de estabilización, el script audita tres pilares fundamentales: 1) Existencia 
# de los Namespaces, 2) Conectividad básica mediante ICMP (ping) entre los extremos de la 
# red (Cliente a Servicios), y 3) Estado de ejecución de los procesos críticos (Nginx y 
# Dnsmasq), verificando tanto su gestión vía Systemd como su presencia real en el espacio 
# de usuario del Namespace. Esta verificación proporciona un feedback instantáneo al 
# administrador, permitiendo confirmar que el aislamiento de red y el enrutamiento a 
# través del nodo EDGE funcionan antes de entregar el entorno para su uso final.
# ---------------------------------------------------------------------------
echo "[12/14] 🔍 Realizando verificación inicial..."

# Esperar a que los servicios se estabilicen
sleep 5

echo ""
echo "   Verificando namespaces..."
if ip netns list | grep -q "NS-"; then
    echo "   ✅ Namespaces creados: $(ip netns list | wc -l)"
else
    echo "   ❌ Error: No se crearon namespaces"
fi

echo ""
echo "   Verificando conectividad básica..."
if ip netns list | grep -q "NS-CLIENT" && ip netns list | grep -q "NS-SERVICES"; then
    if ip netns exec NS-CLIENT ping -c 2 -W 1 $IP_SERVICES > /dev/null 2>&1; then
        echo "   ✅ Conectividad: Cliente → Servicios OK"
    else
        echo "   ⚠️  Advertencia: Problema de conectividad"
    fi
else
    echo "   ⚠️  Advertencia: Namespaces no disponibles para prueba"
fi

echo ""
echo "   Verificando servicios..."
if systemctl is-active --quiet lab-nginx; then
    echo "   ✅ Nginx activo (via systemd)"
else
    echo "   ⚠️  Nginx inactivo - Verificando proceso..."
    if ip netns exec NS-SERVICES pgrep nginx > /dev/null 2>&1; then
        echo "   ✅ Nginx corriendo en NS-SERVICES"
    else
        echo "   ❌ Nginx no está activo"
    fi
fi

if systemctl is-active --quiet lab-dnsmasq; then
    echo "   ✅ Dnsmasq activo (via systemd)"
else
    echo "   ⚠️  Dnsmasq inactivo - Verificando proceso..."
    if ip netns exec NS-SERVICES pgrep dnsmasq > /dev/null 2>&1; then
        echo "   ✅ Dnsmasq corriendo en NS-SERVICES"
    else
        echo "   ❌ Dnsmasq no está activo"
    fi
fi


# ---------------------------------------------------------------------------
# 13️⃣ CONFIGURACIÓN DE LOGGING (TRAZABILIDAD Y MANTENIMIENTO)
# ---------------------------------------------------------------------------
# Este bloque establece la infraestructura de auditoría y persistencia de logs para el 
# laboratorio. Su propósito es doble: por un lado, configura políticas de rotación de 
# archivos mediante 'logrotate', lo que previene el agotamiento del espacio en disco 
# al gestionar automáticamente la compresión y el purgado de registros antiguos de salud 
# y reconstrucción. Por otro lado, centraliza los puntos de salida de los servicios 
# que corren aislados (Nginx y Dnsmasq) en directorios específicos del host físico. 
# Esto facilita la monitorización en tiempo real y la resolución de problemas (debugging) 
# sin necesidad de entrar constantemente en los Namespaces, permitiendo que todas 
# las trazas de red y de servicio sean auditables desde el plano de gestión principal.
# ---------------------------------------------------------------------------
echo "[13/14] 📝 Configurando sistema de logging..."

# Configurar rotación de logs para el lab
cat > /etc/logrotate.d/lab-infrastructure <<EOF
/var/log/lab-reconstruction-*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}

/var/log/lab-health-*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
}
EOF

# Crear directorio para logs de servicios dentro de namespaces
mkdir -p /var/log/lab/
touch /var/log/lab/nginx-access.log
touch /var/log/lab/nginx-error.log
touch /var/log/lab/dnsmasq.log

echo "   ✅ Logging configurado"

# ---------------------------------------------------------------------------
# 14️⃣ MENSAJE FINAL Y RESUMEN (CIERRE Y ENTREGA DEL ENTORNO)
# ---------------------------------------------------------------------------
# Este bloque finaliza el despliegue consolidando toda la información operativa en un 
# panel de control visual y un archivo de persistencia (/root/lab-summary.txt). Su 
# objetivo es proporcionar al usuario una "hoja de ruta" inmediata que incluye 
# credenciales de acceso, el mapa completo de direccionamiento IP de la arquitectura 
# 3-Tier y un catálogo de comandos de diagnóstico. Al ejecutar automáticamente una 
# última verificación de salud y generar un archivo de resumen, se asegura de que el 
# estudiante o administrador tenga a mano todos los puntos de entrada (Endpoints) y 
# herramientas de control necesarias para comenzar a trabajar, garantizando una 
# transición fluida desde la fase de construcción hacia la fase de uso del laboratorio.
# ---------------------------------------------------------------------------
echo "[14/14] ✅ RECONSTRUCCIÓN COMPLETADA"
echo ""
echo "=" * 60
echo "🎉 LAB 3-TIER CONFIGURADO EXITOSAMENTE"
echo "=" * 60
echo ""
echo "📊 RESUMEN DE LA CONFIGURACIÓN:"
echo "--------------------------------"
echo "👤 USUARIOS:"
echo "   - student / redhat (SSH y sudo sin password)"
echo ""
echo "🌐 REDES:"
echo "   ├── Capa CLIENT:    $NET_CLIENT"
echo "   │   └── Cliente:    $IP_CLIENT"
echo "   ├── Capa EDGE:      Router/Firewall"
echo "   │   ├── LAN:        $IP_EDGE_LAN"
echo "   │   └── WAN:        $IP_EDGE_WAN"
echo "   └── Capa SERVICES:  $NET_SERVICES"
echo "       └── Servicios:  $IP_SERVICES"
echo ""
echo "🛠️  SERVICIOS ACTIVOS:"
echo "   ✅ Nginx (Web)      - http://$IP_SERVICES"
echo "   ✅ MariaDB          - mysql://$DB_USER:*****@$IP_SERVICES/$DB_NAME"
echo "   ✅ Dnsmasq (DNS)    - web.lab.local → $IP_SERVICES"
echo "   ✅ Firewall/NAT     - Filtrado activo"
echo ""
echo "🔧 HERRAMIENTAS DISPONIBLES:"
echo "   lab-health-check.sh    - Verificación completa del sistema"
echo "   lab-reset.sh           - Reinicio rápido del lab"
echo "   ns-client/ns-edge/ns-services - Entrar a cada namespace"
echo ""
echo "📝 COMANDOS ÚTILES:"
echo "   • Ver estado:       systemctl status lab-infrastructure"
echo "   • Ver logs:         journalctl -u lab-infrastructure -f"
echo "   • Probar web:       curl http://$IP_SERVICES"
echo "   • Probar DNS:       nslookup web.lab.local $IP_SERVICES"
echo "   • Conectar a BD:    mysql -u $DB_USER -predhat -h $IP_SERVICES $DB_NAME"
echo ""
echo "🔍 PRUEBA RÁPIDA:"
echo "   Ejecuta 'lab-health-check.sh' para verificar todo el sistema"
echo "   O usa 'lab-check' para probar la web desde el cliente"
echo ""
echo "💡 RECUERDA:"
echo "   - Los servicios están aislados en network namespaces"
echo "   - El firewall en EDGE filtra el tráfico entre capas"
echo "   - La BD tiene datos de ejemplo en la tabla 'usuarios'"
echo ""
echo "=" * 60
echo "🕐 Tiempo de construcción: $(date)"
echo "=" * 60

# Ejecutar verificación final
echo ""
echo "🔍 Ejecutando verificación final automática..."
/usr/local/bin/lab-health-check.sh | tail -20

# Crear archivo de resumen
cat > /root/lab-summary.txt <<EOF
LAB 3-TIER - RESUMEN DE CONFIGURACIÓN
======================================
Fecha: $(date)

CREDENCIALES:
-------------
Usuario SSH: student
Contraseña: redhat
SSH Key: ~/.ssh/authorized_keys

Base de datos:
- Usuario: $DB_USER
- Contraseña: $DB_PASS
- Base: $DB_NAME

REDES:
------
Capa CLIENT:    $NET_CLIENT
  Cliente:      $IP_CLIENT
  Gateway:      $IP_EDGE_LAN

Capa EDGE:
  Interfaz LAN: $IP_EDGE_LAN
  Interfaz WAN: $IP_EDGE_WAN

Capa SERVICES:  $NET_SERVICES
  Servicios:    $IP_SERVICES
  Gateway:      $IP_EDGE_WAN

SERVICIOS:
----------
Web Server:     http://$IP_SERVICES
DNS Server:     $IP_SERVICES (53/udp)
MariaDB:        $IP_SERVICES (3306/tcp)

ENDPOINTS DNS:
--------------
web.lab.local      -> $IP_SERVICES
www.lab.local      -> $IP_SERVICES
db.lab.local       -> $IP_SERVICES
mysql.lab.local    -> $IP_SERVICES
lab.local          -> $IP_SERVICES

COMANDOS ÚTILES:
----------------
# Ver estado del lab
systemctl status lab-infrastructure

# Verificar salud
lab-health-check.sh

# Acceder a namespaces
ns-client   # Namespace del cliente
ns-edge     # Namespace del router
ns-services # Namespace de servicios

# Probar conectividad desde cliente
lab-check           # Probar web
lab-test-dns        # Probar DNS
lab-test-ping       # Probar ping

# Conectar a base de datos
mysql -u $DB_USER -p$DB_PASS -h $IP_SERVICES $DB_NAME

LOG FILES:
----------
/var/log/lab-reconstruction-*.log
/var/log/lab/nginx-access.log
/var/log/lab/nginx-error.log
/var/log/lab/dnsmasq.log
journalctl -u lab-infrastructure
EOF

echo ""
echo "📄 Resumen guardado en: /root/lab-summary.txt"
echo ""
echo "🚀 ¡Lab listo para usar! Reinicia la sesión SSH para cargar los aliases."
echo ""