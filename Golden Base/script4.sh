#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   4 de 5 - Orquestación y Automatización (Orchestration Layer)
# ============================================================================
#
# ⏪ CONTEXTO TÉCNICO PREVIO (SCRIPTS 2 y 3):
#
# SCRIPT 2 - GLOBAL NETWORK LAYER
#   - Topología multi-sede con Router Core (NS-ROUTER)
#   - Segmentación geográfica:
#       • ALEMANIA (NS-SERVICES): 10.10.0.10/24
#       • CHINA (NS-CLIENT): 10.20.0.20/24
#       • INDIA (NS-DEV): 10.30.0.30/24
#       • BÚNKER (NS-STORAGE): 10.90.0.50/24
#       • SYSADMIN (NS-SYSADMIN): 172.16.0.100/24
#   - Firewall stateful con políticas de negocio
#   - Persistencia vía systemd (lab-network.service)
#
#   COMANDOS DE VALIDACIÓN:
#     ip netns list
#     lab-network-status
#     ip netns exec NS-ROUTER iptables -L FORWARD -n
#
# SCRIPT 3 - APPLICATION DATA LAYER
#   - MariaDB operativo en BÚNKER (10.90.0.50:3306)
#   - Config-Store global en /etc/lab-configs/global/
#       • nginx-alemania.conf (bind a 10.10.0.10:80)
#       • php-fpm.conf (conexión a DB en Búnker)
#       • api_status.php (API para consultar estado)
#   - Contenido web geo-localizado
#
#   COMANDOS DE VALIDACIÓN:
#     ip netns exec NS-STORAGE systemctl status mariadb
#     ls -la /etc/lab-configs/global/
#     cat /usr/share/nginx/html/index.html | head -10
#
# 🎯 OBJETIVO DE ESTE SCRIPT (SCRIPT 4):
#   - Desplegar servicios en cada sede según políticas de negocio
#   - Instalar y configurar Nginx + PHP-FPM en ALEMANIA (NS-SERVICES)
#   - Instalar herramientas de desarrollo en INDIA (NS-DEV)
#   - Configurar monitoreo básico en todas las sedes
#
# RESULTADO ESPERADO:
#   - curl http://10.10.0.10 → Portal empresarial con conexión a DB
#   - Desde China: curl http://10.10.0.10/public/ → Contenido restringido
#   - Desde India: Acceso total a DB en Búnker
#   - Desde SysAdmin: Acceso irrestricto
# ============================================================================

set -e

echo "=== 🚀 SCRIPT 4: ORQUESTACIÓN GLOBAL MULTI-SEDE ==="
echo "📅 Fecha: $(date)"
echo "🌍 Arquitectura: Topología Global con Router Core"

# ---------------------------------------------------------------------------
# 1. VALIDACIÓN DE CONFIGURACIONES PREVIAS
# ---------------------------------------------------------------------------
echo "[1/6] 🔍 Validando configuraciones globales..."

# Verificar que Script 2 está activo
if ! systemctl is-active --quiet lab-network.service; then
    echo "❌ ERROR: lab-network.service no está activo. Ejecute Script 2."
    exit 1
fi
echo "   ✅ lab-network.service: ACTIVO"

# Verificar configuración de Script 3
REQUIRED_CONFIGS=(
    "/etc/lab-configs/global/nginx-alemania.conf"
    "/etc/lab-configs/global/php-fpm.conf"
    "/etc/lab-configs/global/api_status.php"
    "/usr/share/nginx/html/index.html"
)

for config in "${REQUIRED_CONFIGS[@]}"; do
    if [[ ! -f "$config" ]]; then
        echo "⚠️  ADVERTENCIA: $config no encontrado (¿Script 3 ejecutado?)"
        echo "   Continuando con instalaciones básicas..."
    else
        echo "   ✅ $(basename "$config"): PRESENTE"
    fi
done

# ---------------------------------------------------------------------------
# 2. INSTALACIÓN EN ALEMANIA (NS-SERVICES) - SERVICIOS WEB
# ---------------------------------------------------------------------------
echo "[2/6] 🇩🇪 Configurando Alemania (NS-SERVICES) - Servicios Web..."

ip netns exec NS-SERVICES bash << 'ALEMANIA_INSTALL'
  set -e
  
  echo "   📦 Instalando paquetes web..."
  
  # Instalar Nginx, PHP-FPM y herramientas
  dnf install -y nginx php-fpm php-mysqlnd php-json \
                 net-tools curl wget vim
  
  # Crear estructura de directorios
  mkdir -p /var/log/nginx /run/php-fpm /usr/share/nginx/{html,admin,public}
  chown -R nginx:nginx /var/log/nginx /run/php-fpm
  
  # Copiar configuraciones desde Config-Store
  echo "   ⚙️  Aplicando configuraciones..."
  
  # Nginx - Configuración global
  if [[ -f /etc/lab-configs/global/nginx-alemania.conf ]]; then
      cp /etc/lab-configs/global/nginx-alemania.conf /etc/nginx/nginx.conf
  else
      # Configuración básica si no existe
      cat > /etc/nginx/nginx.conf << 'NGINX_BASIC'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    server {
        listen 10.10.0.10:80;
        server_name _;
        
        root /usr/share/nginx/html;
        index index.html;
        
        location / {
            try_files \$uri \$uri/ =404;
        }
    }
}
NGINX_BASIC
  fi
  
  # PHP-FPM
  if [[ -f /etc/lab-configs/global/php-fpm.conf ]]; then
      cp /etc/lab-configs/global/php-fpm.conf /etc/php-fpm.d/www.conf
  fi
  
  # Script API
  if [[ -f /etc/lab-configs/global/api_status.php ]]; then
      mkdir -p /usr/share/nginx/html/api
      cp /etc/lab-configs/global/api_status.php /usr/share/nginx/html/api/status.php
  fi
  
  # Copiar contenido web (si no está ya)
  if [[ ! -f /usr/share/nginx/html/index.html ]]; then
      cp -r /usr/share/nginx/html/* /usr/share/nginx/html/ 2>/dev/null || true
  fi
  
  # Configurar firewalld interno (opcional)
  firewall-cmd --permanent --add-port=80/tcp
  firewall-cmd --reload
  
  # Habilitar y iniciar servicios
  echo "   🚀 Iniciando servicios..."
  systemctl enable --now nginx php-fpm
  
  # Verificar
  echo "   ✅ Nginx: $(systemctl is-active nginx)"
  echo "   ✅ PHP-FPM: $(systemctl is-active php-fpm)"
  
  echo "   🌐 Dirección: http://10.10.0.10"
ALEMANIA_INSTALL

# ---------------------------------------------------------------------------
# 3. INSTALACIÓN EN BÚNKER (NS-STORAGE) - BASE DE DATOS
# ---------------------------------------------------------------------------
echo "[3/6] 🔐 Configurando Búnker (NS-STORAGE) - Base de Datos..."

ip netns exec NS-STORAGE bash << 'BUNKER_INSTALL'
  set -e
  
  # Verificar que MariaDB está instalado (del Script 3)
  if ! systemctl is-active --quiet mariadb; then
      echo "   📦 Instalando MariaDB..."
      dnf install -y mariadb-server mariadb
      systemctl enable --now mariadb
      
      # Configuración básica si no se hizo en Script 3
      mysql -u root << 'MYSQL_BASIC'
        CREATE DATABASE IF NOT EXISTS lab_global;
        CREATE USER IF NOT EXISTS 'web_srv'@'10.10.0.10' IDENTIFIED BY 'WebToDB123';
        GRANT ALL ON lab_global.* TO 'web_srv'@'10.10.0.10';
        FLUSH PRIVILEGES;
MYSQL_BASIC
  fi
  
  # Instalar herramientas de monitoreo
  dnf install -y net-tools htop mytop
  
  # Configurar firewalld para DB
  firewall-cmd --permanent --add-port=3306/tcp
  firewall-cmd --reload
  
  echo "   ✅ MariaDB: $(systemctl is-active mariadb)"
  echo "   📊 Puerto: 3306 (accesible desde Alemania e India)"
BUNKER_INSTALL

# ---------------------------------------------------------------------------
# 4. INSTALACIÓN EN INDIA (NS-DEV) - HERRAMIENTAS DE DESARROLLO
# ---------------------------------------------------------------------------
echo "[4/6] 🇮🇳 Configurando India (NS-DEV) - Desarrollo..."

ip netns exec NS-DEV bash << 'INDIA_INSTALL'
  set -e
  
  echo "   🛠️  Instalando herramientas de desarrollo..."
  
  # Herramientas básicas
  dnf install -y mysql net-tools curl wget vim \
                 git telnet nmap-ncat tcpdump
  
  # Configurar cliente MySQL
  cat > ~/.my.cnf << 'MYSQL_CLIENT'
[client]
host=10.90.0.50
port=3306
user=dev_ops
password=DevAccess789
database=lab_global
MYSQL_CLIENT
  
  # Script de monitoreo básico
  cat > /usr/local/bin/monitor-lab.sh << 'MONITOR_SCRIPT'
#!/bin/bash
echo "=== MONITOREO LABORATORIO - INDIA ==="
echo "Fecha: $(date)"
echo ""
echo "1. Conectividad:"
ping -c 2 10.90.0.50 >/dev/null && echo "  ✅ Búnker (DB): ACCESIBLE" || echo "  ❌ Búnker: INACCESIBLE"
ping -c 2 10.10.0.10 >/dev/null && echo "  ✅ Alemania (Web): ACCESIBLE" || echo "  ⚠️  Alemania: Restringido (política)"
echo ""
echo "2. Base de Datos:"
timeout 2 mysql -e "SHOW DATABASES;" 2>/dev/null && echo "  ✅ Conexión DB: OK" || echo "  ❌ Conexión DB: FALLÓ"
echo ""
echo "3. Estado del sistema:"
uptime
echo ""
MONITOR_SCRIPT
  chmod +x /usr/local/bin/monitor-lab.sh
  
  echo "   ✅ Herramientas instaladas"
  echo "   📊 Monitor: /usr/local/bin/monitor-lab.sh"
INDIA_INSTALL

# ---------------------------------------------------------------------------
# 5. INSTALACIÓN EN SYSADMIN (NS-SYSADMIN) - HERRAMIENTAS DE ADMIN
# ---------------------------------------------------------------------------
echo "[5/6] 🛡️  Configurando SysAdmin (NS-SYSADMIN) - Administración..."

ip netns exec NS-SYSADMIN bash << 'SYSADMIN_INSTALL'
  set -e
  
  echo "   🔧 Instalando herramientas de administración..."
  
  # Herramientas completas
  dnf install -y net-tools curl wget vim nmap \
                 tcpdump telnet mariadb \
                 htop iotop iftop
  
  # Script de auditoría completa
  cat > /usr/local/bin/audit-lab.sh << 'AUDIT_SCRIPT'
#!/bin/bash
echo "=== AUDITORÍA COMPLETA - SYSADMIN ==="
echo "IP: 172.16.0.100 | Acceso: TOTAL"
echo "====================================="
echo ""
echo "1. ESTADO DE RED:"
echo "   Desde SysAdmin →"
ping -c 1 10.10.0.10 >/dev/null && echo "   ✅ Alemania (Web)" || echo "   ❌ Alemania"
ping -c 1 10.90.0.50 >/dev/null && echo "   ✅ Búnker (DB)" || echo "   ❌ Búnker"
ping -c 1 10.20.0.20 >/dev/null && echo "   ✅ China (Cliente)" || echo "   ❌ China"
ping -c 1 10.30.0.30 >/dev/null && echo "   ✅ India (Dev)" || echo "   ❌ India"
echo ""
echo "2. SERVICIOS WEB (Alemania):"
curl -s -I http://10.10.0.10 | head -1 && echo "   ✅ Web operativa" || echo "   ❌ Web no responde"
echo ""
echo "3. BASE DE DATOS (Búnker):"
timeout 2 mysql -h 10.90.0.50 -u sys_admin -p'AdminFullAccess!' -e "SELECT '✅ DB Operativa' as Status;" 2>/dev/null || echo "   ❌ DB no accesible"
echo ""
echo "4. POLÍTICAS DE FIREWALL:"
echo "   (Ejecutar desde host: ip netns exec NS-ROUTER iptables -L FORWARD -n)"
echo ""
AUDIT_SCRIPT
  chmod +x /usr/local/bin/audit-lab.sh
  
  # Configurar acceso SSH (opcional)
  dnf install -y openssh-server
  systemctl enable --now sshd
  
  echo "   ✅ Herramientas de admin instaladas"
  echo "   📊 Auditoría: /usr/local/bin/audit-lab.sh"
  echo "   🔐 SSH: Puerto 22 (localhost del namespace)"
SYSADMIN_INSTALL

# ---------------------------------------------------------------------------
# 6. SERVICIOS SYSTEMD PERSISTENTES
# ---------------------------------------------------------------------------
echo "[6/6] ⚙️  Configurando persistencia systemd..."

# Servicio para monitoreo automático
cat > /etc/systemd/system/lab-monitor.service << 'EOF'
[Unit]
Description=Laboratorio Global - Monitor de Estado
After=lab-network.service
Wants=lab-network.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '
  echo "=== 🕐 INICIO MONITOREO: $(date) ==="
  echo "Sistema: Golden Image - Arquitectura Global"
  echo ""
  echo "🧪 Pruebas rápidas:"
  echo -n "  Web Alemania: "
  ip netns exec NS-CLIENT curl -s -o /dev/null -w "%{http_code}" http://10.10.0.10 --connect-timeout 2 && echo "✅" || echo "❌"
  echo -n "  DB Búnker: "
  ip netns exec NS-SERVICES timeout 2 bash -c "echo > /dev/tcp/10.90.0.50/3306" && echo "✅" || echo "❌"
  echo ""
  echo "=== ✅ MONITOREO COMPLETADO ==="
'

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/lab-monitor.timer << 'EOF'
[Unit]
Description=Timer para monitoreo periódico del laboratorio

[Timer]
OnBootSec=5min
OnUnitActiveSec=10min
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Configurar DNS automático para namespaces
mkdir -p /etc/netns/NS-CLIENT
echo "nameserver 8.8.8.8" > /etc/netns/NS-CLIENT/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/netns/NS-CLIENT/resolv.conf

mkdir -p /etc/netns/NS-SYSADMIN
echo "nameserver 10.10.0.10" > /etc/netns/NS-SYSADMIN/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/netns/NS-SYSADMIN/resolv.conf

# Activar servicios
systemctl daemon-reload
systemctl enable --now lab-monitor.timer

# ---------------------------------------------------------------------------
# FINAL - VERIFICACIÓN
# ---------------------------------------------------------------------------
echo ""
echo "================================================================"
echo "✅ SCRIPT 4 - ORQUESTACIÓN GLOBAL COMPLETADA"
echo "================================================================"
echo ""
echo "🌍 INFRAESTRUCTURA DESPLEGADA:"
echo ""
echo "🇩🇪 ALEMANIA (NS-SERVICES):"
echo "   • IP: 10.10.0.10"
echo "   • Servicios: Nginx + PHP-FPM"
echo "   • Web: http://10.10.0.10"
echo "   • API: http://10.10.0.10/api/status.php"
echo ""
echo "🔐 BÚNKER (NS-STORAGE):"
echo "   • IP: 10.90.0.50"
echo "   • Servicio: MariaDB (3306)"
echo "   • Acceso: Alemania (web_srv) | India (dev_ops)"
echo ""
echo "🇮🇳 INDIA (NS-DEV):"
echo "   • IP: 10.30.0.30"
echo "   • Herramientas: MySQL client, monitor"
echo "   • Script: /usr/local/bin/monitor-lab.sh"
echo ""
echo "🛡️  SYSADMIN (NS-SYSADMIN):"
echo "   • IP: 172.16.0.100"
echo "   • Herramientas: Auditoría completa"
echo "   • Script: /usr/local/bin/audit-lab.sh"
echo ""
echo "🇨🇳 CHINA (NS-CLIENT):"
echo "   • IP: 10.20.0.20"
echo "   • Acceso: Solo web pública (80/443)"
echo ""
echo "⚙️  SERVICIOS SYSTEMD:"
echo "   • lab-monitor.timer: Monitoreo cada 10min"
echo ""
echo "================================================================"
echo "🧪 VERIFICACIÓN RÁPIDA:"
echo "   lab-network-status"
echo "   ip netns exec NS-SYSADMIN /usr/local/bin/audit-lab.sh"
echo "================================================================"