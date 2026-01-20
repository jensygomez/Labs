#!/bin/bash
# ============================================================================
# 🚀 LAB COMPLETO – RECOVERY/INITIAL SETUP SCRIPT
# ============================================================================
# TIPO      : SCRIPT DE RECONSTRUCCIÓN COMPLETA
# PROPÓSITO : Reconstruir TODO el ecosistema lab desde cero en una VM nueva
#             Incluye: servicios + namespaces + networking + configuraciones
#
# CARACTERÍSTICAS:
#   - Idempotente (se puede ejecutar múltiples veces)
#   - Recuperación completa después de pérdida de VM
#   - Todo queda funcionando al reiniciar
#   - Documentación ejecutable integrada
#
# DISEÑO:
#   - Una sola VM (limitación de hardware)
#   - Infraestructura interna simulada con Linux puro
#   - Acceso remoto SIEMPRE por SSH (Home Office / NOC)
#
# ALCANCE:
#   - Junior → Pleno → Senior (escalable)
#
# USO:
#   Ejecutar en VM limpia de Rocky Linux 9 → Snapshot listo para labs
#
# AUTOR    : Jensy Gomez
# OS BASE  : Rocky Linux 9.x
# ============================================================================

set -euo pipefail
exec > >(tee -a /var/log/lab-setup.log) 2>&1

# ---------------------------------------------------------------------------
# 📐 SECCIÓN DE DOCUMENTACIÓN EJECUTABLE
# ---------------------------------------------------------------------------
clear
echo ""
echo "==================== 📐 ARQUITECTURA OFICIAL ===================="
echo ""
echo "                        [ INTERNET ]"
echo "                     (Red externa real)"
echo "                              ▲"
echo "                              │ NAT"
echo "                         enp1s0│"
echo "                ┌─────────────┴─────────────┐"
echo "                │           NS-EDGE          │"
echo "                │     Router / Firewall      │"
echo "                │                             │"
echo "                │  WAN: 10.0.0.1/24           │"
echo "                │  LAN: 10.10.50.1/24         │"
echo "                │                             │"
echo "                │  Funciones:                 │"
echo "                │   - NAT                     │"
echo "                │   - Firewall                │"
echo "                │   - Traffic Control (tc)    │"
echo "                └─────────────▲─────────────┘"
echo "                              │"
echo "                ┌─────────────┴─────────────┐"
echo "                │          NS-CLIENT         │"
echo "                │     Usuario / Cliente      │"
echo "                │                             │"
echo "                │  IP : 10.10.50.10/24        │"
echo "                │  GW : 10.10.50.1            │"
echo "                │  DNS: 10.10.40.10           │"
echo "                │                             │"
echo "                │  Simula: Usuario final      │"
echo "                │  curl / ping / navegador    │"
echo "                └─────────────┬─────────────┘"
echo "                              │"
echo "      ====================================================="
echo "      |             VM PRINCIPAL (SERVICES)              |"
echo "      |                                                    |"
echo "      |  MGMT / SSH (SIEMPRE DISPONIBLE)                  |"
echo "      |  enp1s0 → 192.168.122.0/24 (libvirt NAT)           |"
echo "      |                                                    |"
echo "      |  Servicios internos (dummy interfaces):           |"
echo "      |                                                    |"
echo "      |   dummy-web    → 10.10.10.10  (nginx)             |"
echo "      |   dummy-db     → 10.10.20.10  (mariadb)           |"
echo "      |   dummy-proxy  → 10.10.30.10  (squid)             |"
echo "      |   dummy-dns    → 10.10.40.10  (dnsmasq)           |"
echo "      |                                                    |"
echo "      |  🔐 Plano de gestión separado del plano de datos  |"
echo "      ====================================================="
echo ""

echo "==================== 🎯 PRINCIPIOS DEL DISEÑO ===================="
echo ""
echo "✅ Una sola VM (ahorro de recursos)"
echo "✅ SSH nunca se rompe (Home Office real)"
echo "✅ Cliente separado del servidor"
echo "✅ Edge como punto de fallo controlado"
echo "✅ Linux puro (ip, firewall, tc, namespaces)"
echo ""

echo "==================== 🔧 MODELO DE INCIDENTES ===================="
echo ""
echo "Los fallos SIEMPRE se inyectan en:"
echo "- 🎯 NS-EDGE (router/firewall)"
echo "- 🎯 NS-CLIENT (usuario/cliente)"
echo "- 🎯 Servicios internos"
echo ""
echo "⚠️  El plano de gestión (SSH) NO se rompe nunca."
echo ""

echo "==================== 📈 ESCALABILIDAD ===================="
echo ""
echo "👶 Junior    : Diagnóstico básico (ping, DNS, puertos)"
echo "👨‍💼 Pleno    : Routing, NAT, firewall stateful, tc"
echo "👨‍🔬 Senior    : Observabilidad, hardening, simulación realista"
echo ""

echo "==================== 🚀 INICIANDO RECONSTRUCCIÓN ===================="
echo ""
read -p "¿Desea continuar con la reconstrucción completa? (s/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Reconstrucción cancelada por el usuario."
    exit 0
fi

echo ""
echo "=== 🚀 [LAB COMPLETO] Iniciando reconstrucción del ecosistema ==="
echo "📅 Fecha: $(date)"
echo "🖥️  Hostname: $(hostname)"
sleep 2

# ---------------------------------------------------------------------------
# CONFIGURACIÓN GLOBAL
# ---------------------------------------------------------------------------
readonly LAN_SUBNET="10.10.50.0/24"
readonly EDGE_IP="10.10.50.1"
readonly CLIENT_IP="10.10.50.10"
readonly DNS_IP="10.10.40.10"

# Servicios internos
declare -A SERVICES=(
    ["web"]="10.10.10.10"
    ["db"]="10.10.20.10" 
    ["proxy"]="10.10.30.10"
    ["dns"]="10.10.40.10"
)

# ---------------------------------------------------------------------------
# 1️⃣ VERIFICACIÓN INICIAL Y PREPARACIÓN
# ---------------------------------------------------------------------------
echo ""
echo "[1/12] 🔍 Verificando entorno y preparando sistema..."

# Verificar que estamos en Rocky Linux 9
if ! grep -q "Rocky Linux.*9" /etc/os-release; then
    echo "❌ ERROR: Este script requiere Rocky Linux 9"
    exit 1
fi

# Verificar privilegios
if [[ $EUID -ne 0 ]]; then
    echo "❌ ERROR: Debe ejecutarse como root"
    exit 1
fi

# Limpiar posibles configuraciones previas
cleanup_previous() {
    echo "   🧹 Limpiando configuraciones previas..."
    
    # Limpiar namespaces si existen
    ip netns delete NS-EDGE 2>/dev/null || true
    ip netns delete NS-CLIENT 2>/dev/null || true
    
    # Limpiar interfaces dummy antiguas
    for iface in dummy-web dummy-db dummy-proxy dummy-dns; do
        ip link delete $iface 2>/dev/null || true
    done
    
    # Limpiar veth pairs
    ip link delete veth-edge 2>/dev/null || true
    for service in "${!SERVICES[@]}"; do
        ip link delete veth-$service 2>/dev/null || true
        ip link delete br-$service 2>/dev/null || true
    done
    
    rm -rf /etc/netns/NS-CLIENT
}

cleanup_previous
echo "✅ Verificación completada"
sleep 1

# ---------------------------------------------------------------------------
# 2️⃣ INSTALACIÓN DE PAQUETES ESENCIALES
# ---------------------------------------------------------------------------
echo ""
echo "[2/12] 📦 Instalando paquetes esenciales..."

dnf update -y --quiet

# Paquetes base
dnf install -y \
    epel-release \
    nginx \
    mariadb-server \
    squid \
    dnsmasq \
    firewalld \
    bind-utils \
    iproute \
    iproute-tc \
    tcpdump \
    policycoreutils-python-utils \
    conntrack-tools \
    iptables-services \
    net-tools \
    tcpdump \
    traceroute \
    telnet \
    nmap \
    wget \
    curl \
    vim-enhanced \
    bash-completion \
    cloud-init \
    qemu-guest-agent

echo "✅ Paquetes instalados"
sleep 1

# ---------------------------------------------------------------------------
# 3️⃣ CONFIGURACIÓN DE CLOUD-INIT
# ---------------------------------------------------------------------------
echo ""
echo "[3/12] ☁️  Configurando cloud-init para recuperación..."

systemctl enable \
    cloud-init-local \
    cloud-init \
    cloud-config \
    cloud-final \
    qemu-guest-agent

cat > /etc/cloud/cloud.cfg.d/90_libvirt.cfg <<'EOF'
datasource_list: [ NoCloud, None ]
disable_ec2_metadata: true
EOF

rm -rf /var/lib/cloud/* /var/log/cloud-init*
echo "✅ Cloud-init configurado"
sleep 1

# ---------------------------------------------------------------------------
# 4️⃣ USUARIO STUDENT Y SSH (PLANO DE GESTIÓN)
# ---------------------------------------------------------------------------
echo ""
echo "[4/12] 👤 Configurando usuario student y SSH..."

# Crear usuario student si no existe
if ! id "student" &>/dev/null; then
    useradd -m -G wheel -s /bin/bash student
    echo "student:redhat" | chpasswd
fi

# Configurar sudo sin password
echo "student ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/student
chmod 440 /etc/sudoers.d/student

# Configurar SSH para student
mkdir -p /home/student/.ssh
cat > /home/student/.ssh/authorized_keys <<'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByFDKwjMDeGJ5GRhXmZHa75h7dK9JcPHvWWtesSO3/x RHCSA Storage Labs
EOF

chmod 700 /home/student/.ssh
chmod 600 /home/student/.ssh/authorized_keys
chown -R student:student /home/student/.ssh

# Configurar SSH daemon
cat > /etc/ssh/sshd_config.d/99-labs.conf <<EOF
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
UseDNS no
ClientAliveInterval 60
ClientAliveCountMax 3
EOF

systemctl restart sshd
echo "✅ SSH y usuario configurados"
sleep 1

# ---------------------------------------------------------------------------
# 5️⃣ SERVICIOS INTERNOS (INTERFACES DUMMY)
# ---------------------------------------------------------------------------
echo ""
echo "[5/12] 🖥️  Configurando servicios internos..."

# Crear interfaces dummy para servicios (INMEDIATO)
for service in "${!SERVICES[@]}"; do
    ip link add dummy-$service type dummy 2>/dev/null || true
    ip addr add "${SERVICES[$service]}/24" dev dummy-$service 2>/dev/null || true
    ip link set dummy-$service up 2>/dev/null || true
    echo "   ✅ dummy-$service: ${SERVICES[$service]}"
done

# Crear scripts auxiliares para systemd (SOLUCIÓN DEFINITIVA)
cat > /usr/local/bin/lab-dummy-start.sh <<'EOF'
#!/bin/bash
set -euo pipefail
for service in web db proxy dns; do
    ip link add dummy-$service type dummy 2>/dev/null || true
    case $service in
        web) ip="10.10.10.10/24" ;;
        db) ip="10.10.20.10/24" ;;
        proxy) ip="10.10.30.10/24" ;;
        dns) ip="10.10.40.10/24" ;;
    esac
    ip addr add $ip dev dummy-$service 2>/dev/null || true
    ip link set dummy-$service up 2>/dev/null || true
done
EOF

cat > /usr/local/bin/lab-dummy-stop.sh <<'EOF'
#!/bin/bash
set -euo pipefail
for service in web db proxy dns; do
    ip link del dummy-$service 2>/dev/null || true
done
EOF

chmod +x /usr/local/bin/lab-dummy-*.sh

# Crear servicio systemd CORRECTO
cat > /etc/systemd/system/lab-dummy-net.service <<'EOF'
[Unit]
Description=Lab Dummy Interfaces
After=network.target
Wants=network.target

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/usr/local/bin/lab-dummy-start.sh
ExecStop=/usr/local/bin/lab-dummy-stop.sh

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now lab-dummy-net.service
echo "✅ Interfaces dummy configuradas"
sleep 1


# ---------------------------------------------------------------------------
# 6️⃣ CONFIGURACIÓN DE SERVICIOS
# ---------------------------------------------------------------------------
echo ""
echo "[6/12] ⚙️  Configurando servicios..."

# NGINX - Servicio web simple
cat > /etc/nginx/nginx.conf <<'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    server {
        listen       10.10.10.10:80;
        server_name  _;
        
        location / {
            return 200 "✅ SERVICIO WEB OPERATIVO\nHost: $(hostname)\nTime: $(date)\nIP: 10.10.10.10\n";
            add_header Content-Type text/plain;
        }
        
        location /status {
            stub_status on;
            access_log off;
            allow 10.10.50.0/24;
            deny all;
        }
    }
}
EOF

# DNSmasq - Servidor DNS
cat > /etc/dnsmasq.conf <<EOF
# Configuración básica
interface=dummy-dns
bind-interfaces
listen-address=${SERVICES[dns]}
no-dhcp-interface=dummy-dns

# Cache DNS
cache-size=1000
local-ttl=300

# Dominio local
domain=lab.local
expand-hosts
local=/lab.local/

# Registros estáticos
address=/web.lab.local/${SERVICES[web]}
address=/db.lab.local/${SERVICES[db]}
address=/proxy.lab.local/${SERVICES[proxy]}
address=/dns.lab.local/${SERVICES[dns]}
address=/edge.lab.local/${EDGE_IP}
address=/client.lab.local/${CLIENT_IP}

# Forwarders
server=8.8.8.8
server=1.1.1.1
EOF

# Squid - Proxy
cat > /etc/squid/squid.conf <<EOF
http_port ${SERVICES[proxy]}:3128

acl localnet src ${LAN_SUBNET}
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 443
acl CONNECT method CONNECT

http_access allow localnet
http_access deny all

cache_dir ufs /var/spool/squid 100 16 256
coredump_dir /var/spool/squid

refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\\?) 0     0%      0
refresh_pattern .               0       20%     4320

visible_hostname proxy.lab.local
EOF

# MariaDB - Configuración básica
cat > /etc/my.cnf.d/lab.cnf <<EOF
[mysqld]
bind-address = ${SERVICES[db]}
skip-name-resolve
innodb_buffer_pool_size = 128M
max_connections = 50
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
EOF

# Habilitar e iniciar servicios
for service in nginx mariadb squid dnsmasq; do
    systemctl enable --now $service
done

# Inicializar MariaDB si es primera vez
if [[ ! -d /var/lib/mysql/mysql ]]; then
    echo "   🗄️  Inicializando MariaDB..."
    mysql_install_db --user=mysql
    systemctl restart mariadb
    
    # Configurar root sin password para lab (¡Solo para entornos de prueba!)
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '';"
    mysql -e "FLUSH PRIVILEGES;"
    
    # Crear base de datos de ejemplo
    mysql -e "CREATE DATABASE IF NOT EXISTS lab_db;"
    mysql -e "CREATE USER IF NOT EXISTS 'lab_user'@'10.10.50.%' IDENTIFIED BY 'LabPass123';"
    mysql -e "GRANT ALL ON lab_db.* TO 'lab_user'@'10.10.50.%';"
fi

echo "✅ Servicios configurados y operativos"
sleep 2

# ---------------------------------------------------------------------------
# 7️⃣ CREACIÓN DE NAMESPACES
# ---------------------------------------------------------------------------
echo ""
echo "[7/12] 🏗️  Creando namespaces..."

# Crear namespaces
ip netns add NS-EDGE
ip netns add NS-CLIENT

# Configurar loopback en cada namespace
ip netns exec NS-EDGE ip link set lo up
ip netns exec NS-CLIENT ip link set lo up

echo "✅ Namespaces creados: NS-EDGE, NS-CLIENT"
sleep 1

# ---------------------------------------------------------------------------
# 8️⃣ RED INTERNA NS-EDGE ↔ NS-CLIENT
# ---------------------------------------------------------------------------
echo ""
echo "[8/12] 🌐 Configurando red interna..."

# Crear veth pair para conectar EDGE y CLIENT
ip link add veth-edge type veth peer name veth-client

# Configurar NS-EDGE
ip link set veth-edge netns NS-EDGE
ip netns exec NS-EDGE ip link set veth-edge up
ip netns exec NS-EDGE ip addr add ${EDGE_IP}/24 dev veth-edge

# Configurar NS-CLIENT  
ip link set veth-client netns NS-CLIENT
ip netns exec NS-CLIENT ip link set veth-client up
ip netns exec NS-CLIENT ip addr add ${CLIENT_IP}/24 dev veth-client
ip netns exec NS-CLIENT ip route add default via ${EDGE_IP}

echo "✅ Red interna configurada:"
echo "   NS-EDGE: ${EDGE_IP}/24 (veth-edge)"
echo "   NS-CLIENT: ${CLIENT_IP}/24 (veth-client)"
sleep 1

# ---------------------------------------------------------------------------
# 9️⃣ CONEXIÓN SERVICIOS ↔ NS-EDGE
# ---------------------------------------------------------------------------
echo ""
echo "[9/12] 🔗 Conectando servicios a NS-EDGE..."

# Directorio para configuraciones por namespace
mkdir -p /etc/netns/NS-CLIENT
mkdir -p /etc/netns/NS-EDGE

# Para cada servicio, crear bridge en NS-EDGE
for service in "${!SERVICES[@]}"; do
    # Crear veth pair
    ip link add veth-$service type veth peer name br-$service
    
    # Mover bridge a NS-EDGE
    ip link set br-$service netns NS-EDGE
    ip netns exec NS-EDGE ip link set br-$service up
    ip netns exec NS-EDGE ip addr add ${SERVICES[$service]}/24 dev br-$service
    
    # Configurar servicio (lado host)
    ip link set veth-$service up
    
    # Conectar servicio a su interface dummy
    ip link set veth-$service master dummy-$service 2>/dev/null || true
    
    echo "   ✅ $service: ${SERVICES[$service]} → NS-EDGE"
done

echo "✅ Servicios conectados a NS-EDGE"
sleep 1

# ---------------------------------------------------------------------------
# 🔟 CONFIGURACIÓN DE ROUTING Y FIREWALL EN NS-EDGE
# ---------------------------------------------------------------------------
echo ""
echo "[10/12] 🛡️  Configurando routing y firewall en NS-EDGE..."

# Habilitar IP forwarding en NS-EDGE
ip netns exec NS-EDGE sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ns-edge.conf

# Configurar NAT en NS-EDGE
ip netns exec NS-EDGE iptables -t nat -A POSTROUTING -s ${LAN_SUBNET} -j MASQUERADE

# Reglas básicas de firewall en NS-EDGE
ip netns exec NS-EDGE iptables -P INPUT DROP
ip netns exec NS-EDGE iptables -P FORWARD DROP
ip netns exec NS-EDGE iptables -P OUTPUT ACCEPT

# Permitir tráfico establecido
ip netns exec NS-EDGE iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
ip netns exec NS-EDGE iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Permitir loopback
ip netns exec NS-EDGE iptables -A INPUT -i lo -j ACCEPT

# Permitir ping
ip netns exec NS-EDGE iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
ip netns exec NS-EDGE iptables -A FORWARD -p icmp --icmp-type echo-request -j ACCEPT

# Permitir SSH desde cualquier lado (para diagnóstico)
ip netns exec NS-EDGE iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Reglas de FORWARDING específicas
for service in "${!SERVICES[@]}"; do
    # Permitir tráfico CLIENT → SERVICIO
    ip netns exec NS-EDGE iptables -A FORWARD -i veth-edge -o br-$service -j ACCEPT
    # Permitir tráfico SERVICIO → CLIENT (respuestas)
    ip netns exec NS-EDGE iptables -A FORWARD -i br-$service -o veth-edge -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Reglas INPUT para servicios
    case $service in
        web)
            ip netns exec NS-EDGE iptables -A INPUT -i br-web -p tcp --dport 80 -j ACCEPT
            ;;
        dns)
            ip netns exec NS-EDGE iptables -A INPUT -i br-dns -p udp --dport 53 -j ACCEPT
            ip netns exec NS-EDGE iptables -A INPUT -i br-dns -p tcp --dport 53 -j ACCEPT
            ;;
        proxy)
            ip netns exec NS-EDGE iptables -A INPUT -i br-proxy -p tcp --dport 3128 -j ACCEPT
            ;;
    esac
done

# Guardar reglas iptables
mkdir -p /etc/netns/NS-EDGE
ip netns exec NS-EDGE iptables-save > /etc/netns/NS-EDGE/iptables.rules

echo "✅ Routing y firewall configurados en NS-EDGE"
sleep 1

# ---------------------------------------------------------------------------
# 1️⃣1️⃣ CONFIGURACIÓN DE NS-CLIENT
# ---------------------------------------------------------------------------
echo ""
echo "[11/12] 💻 Configurando NS-CLIENT..."

# Configurar resolv.conf para NS-CLIENT
cat > /etc/netns/NS-CLIENT/resolv.conf <<EOF
# DNS Configuration for NS-CLIENT
nameserver ${DNS_IP}
nameserver 8.8.8.8
search lab.local
options timeout:2 attempts:3
EOF

# Crear script de diagnóstico para NS-CLIENT
cat > /usr/local/bin/client-diag <<'EOF'
#!/bin/bash
echo "=== 🔍 DIAGNÓSTICO CLIENT ==="
echo ""
echo "📡 Información de red:"
echo "  IP: $(hostname -I 2>/dev/null || ip -4 addr show veth-client | grep inet | awk '{print $2}')"
echo "  Gateway: $(ip route | grep default | awk '{print $3}' 2>/dev/null || echo "No configurado")"
echo "  DNS: $(grep nameserver /etc/resolv.conf 2>/dev/null | head -2)"
echo ""
echo "--- 🌐 Conectividad básica ---"
ping -c 2 -W 1 10.10.50.1 >/dev/null 2>&1 && echo "  ✅ Gateway (10.10.50.1): OK" || echo "  ❌ Gateway (10.10.50.1): FAIL"
ping -c 2 -W 1 10.10.10.10 >/dev/null 2>&1 && echo "  ✅ Web (10.10.10.10): OK" || echo "  ❌ Web (10.10.10.10): FAIL"
ping -c 2 -W 1 10.10.40.10 >/dev/null 2>&1 && echo "  ✅ DNS (10.10.40.10): OK" || echo "  ❌ DNS (10.10.40.10): FAIL"
echo ""
echo "--- 🔗 Resolución DNS ---"
nslookup web.lab.local >/dev/null 2>&1 && echo "  ✅ web.lab.local: Resuelve OK" || echo "  ❌ web.lab.local: FAIL"
nslookup google.com >/dev/null 2>&1 && echo "  ✅ google.com: Resuelve OK" || echo "  ❌ google.com: FAIL"
echo ""
echo "=== ✅ FIN DEL DIAGNÓSTICO ==="
EOF

chmod +x /usr/local/bin/client-diag
cp /usr/local/bin/client-diag /etc/netns/NS-CLIENT/
echo "✅ NS-CLIENT configurado"
sleep 1

# ---------------------------------------------------------------------------
# 1️⃣2️⃣ FINALIZACIÓN Y VERIFICACIÓN
# ---------------------------------------------------------------------------
echo ""
echo "[12/12] ✅ Finalizando y verificando..."

# Crear scripts auxiliares para namespaces (SOLUCIÓN DEFINITIVA)
mkdir -p /usr/local/bin/lab-ns
cat > /usr/local/bin/lab-ns-start.sh <<'EOF'
#!/bin/bash
set -euo pipefail
# Crear namespaces si no existen
ip netns add NS-EDGE 2>/dev/null || true
ip netns add NS-CLIENT 2>/dev/null || true
# Loopback UP
ip netns exec NS-EDGE ip link set lo up 2>/dev/null || true
ip netns exec NS-CLIENT ip link set lo up 2>/dev/null || true
# Forwarding permanente
ip netns exec NS-EDGE sysctl -w net.ipv4.ip_forward=1 2>/dev/null || true
# Restaurar iptables si existe
if [ -f /etc/netns/NS-EDGE/iptables.rules ]; then
    ip netns exec NS-EDGE iptables-restore < /etc/netns/NS-EDGE/iptables.rules 2>/dev/null || true
fi
EOF

cat > /usr/local/bin/lab-ns-stop.sh <<'EOF'
#!/bin/bash
# No destruimos namespaces (persistencia)
true
EOF

chmod +x /usr/local/bin/lab-ns-*.sh

# Crear servicio systemd CORRECTO para namespaces
cat > /etc/systemd/system/lab-namespaces.service <<'EOF'
[Unit]
Description=Lab Network Namespaces
After=network.target lab-dummy-net.service
Requires=lab-dummy-net.service

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/usr/local/bin/lab-ns-start.sh
ExecStop=/usr/local/bin/lab-ns-stop.sh

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now lab-namespaces.service















# Crear archivo de información del lab
cat > /etc/lab.info <<EOF
=== 🏗️ LAB COMPLETO - ECOSISTEMA OPERATIVO ===
Creado: $(date)
Versión: 2.0 (Arquitectura Oficial)
Estado: OPERATIVO

📐 ARQUITECTURA (Documentación Ejecutable):
├── Una sola VM (limitación de hardware)
├── Infraestructura interna simulada con Linux puro
├── Acceso remoto SIEMPRE por SSH (Home Office / NOC)
├── Plano de gestión separado del plano de datos
└── Puntos de fallo controlados: NS-EDGE, NS-CLIENT, Servicios

📊 TOPOLOGÍA:
├── VM Principal (Gestión)
│   ├── SSH: 192.168.122.0/24 (siempre disponible)
│   └── Servicios internos (dummy interfaces)
├── NS-EDGE (Router/Firewall)
│   ├── LAN: 10.10.50.1/24
│   ├── NAT: Habilitado
│   └── Firewall: Configurado
└── NS-CLIENT (Usuario)
    ├── IP: 10.10.50.10/24
    ├── GW: 10.10.50.1
    └── DNS: 10.10.40.10

🌐 SERVICIOS:
• 🌐 Web:     10.10.10.10 (nginx)
• 🗄️  DB:      10.10.20.10 (mariadb)
• 🔄 Proxy:   10.10.30.10:3128 (squid)
• 🔗 DNS:     10.10.40.10 (dnsmasq)

🔧 COMANDOS ÚTILES:
# Entrar a namespaces
sudo ip netns exec NS-EDGE bash
sudo ip netns exec NS-CLIENT bash

# Diagnóstico
sudo ip netns exec NS-CLIENT client-diag
sudo ip netns exec NS-EDGE iptables -L -n -v

# Ver estado
sudo systemctl status lab-namespaces
sudo systemctl status lab-dummy-net

📈 ESCALABILIDAD:
• 👶 Junior: Diagnóstico básico (ping, DNS, puertos)
• 👨‍💼 Pleno: Routing, NAT, firewall stateful, tc
• 👨‍🔬 Senior: Observabilidad, hardening, simulación realista

🎯 MODELO DE INCIDENTES:
Los fallos SIEMPRE se inyectan en:
- NS-EDGE (router/firewall)
- NS-CLIENT (usuario/cliente)
- Servicios internos

⚠️  El plano de gestión (SSH) NO se rompe nunca.

🔐 AUTOR: Jensy Gomez
🖥️  OS BASE: Rocky Linux 9.x
EOF

# Script de verificación rápida
cat > /usr/local/bin/lab-status <<'EOF'
#!/bin/bash
echo "=== 🧪 LAB STATUS CHECK ==="
echo ""
echo "📦 Servicios del host:"
for svc in nginx mariadb squid dnsmasq lab-dummy-net lab-namespaces; do
    if systemctl is-active --quiet $svc; then
        echo "  ✅ $svc: ACTIVE"
    else
        echo "  ❌ $svc: INACTIVE"
    fi
done

echo ""
echo "🏗️  Namespaces:"
for ns in NS-EDGE NS-CLIENT; do
    if ip netns list | grep -q $ns; then
        echo "  ✅ $ns: EXISTS"
        if ip netns exec $ns ip link show 2>/dev/null | grep -q "state UP"; then
            echo "     📡 Interfaces: UP"
        else
            echo "     ⚠️  Interfaces: DOWN or missing"
        fi
    else
        echo "  ❌ $ns: MISSING"
    fi
done

echo ""
echo "🌐 Interfaces dummy:"
for iface in dummy-web dummy-db dummy-proxy dummy-dns; do
    if ip link show $iface >/dev/null 2>&1; then
        ip_addr=$(ip -4 addr show $iface | grep inet | awk '{print $2}')
        echo "  ✅ $iface: UP ($ip_addr)"
    else
        echo "  ❌ $iface: DOWN"
    fi
done

echo ""
echo "🔗 Conectividad básica:"
if ip netns exec NS-CLIENT ping -c 1 -W 1 10.10.50.1 >/dev/null 2>&1; then
    echo "  ✅ NS-CLIENT → NS-EDGE: OK"
else
    echo "  ❌ NS-CLIENT → NS-EDGE: FAIL"
fi

if ip netns exec NS-CLIENT ping -c 1 -W 1 10.10.10.10 >/dev/null 2>&1; then
    echo "  ✅ NS-CLIENT → Web Service: OK"
else
    echo "  ❌ NS-CLIENT → Web Service: FAIL"
fi

echo ""
echo "=== 📋 FIN DEL REPORTE ==="
echo ""
echo "💡 Para diagnóstico detallado: sudo ip netns exec NS-CLIENT client-diag"
EOF

chmod +x /usr/local/bin/lab-status

# ---------------------------------------------------------------------------
# 🎉 RESUMEN VISUAL SIMPLE
# ---------------------------------------------------------------------------
clear
echo ""
echo "=========================================================="
echo "🎉 ¡LAB COMPLETO - READY FOR INCIDENTS!"
echo "=========================================================="
echo ""
echo "🔄 Verificando componentes internos..."
echo ""
sleep 1

# Verificación rápida y visual
echo "✅ Servicios:   $(systemctl is-active nginx mariadb squid dnsmasq 2>/dev/null | grep -c 'active' | awk '{print $1"/4"}') activos"
echo "✅ Namespaces:  $(ip netns list | wc -l)/2 creados"
echo "✅ Interfaces:  $(ip link show | grep -c 'dummy-' | awk '{print $1"/4"}') dummy UP"
echo "✅ Conectividad: $(ip netns exec NS-CLIENT ping -c1 -W1 10.10.50.1 >/dev/null 2>&1 && echo 'CLIENT→EDGE OK' || echo 'CLIENT→EDGE FAIL')"
echo "✅ Web:        $(ip netns exec NS-CLIENT curl -s --max-time 2 http://10.10.10.10 >/dev/null 2>&1 && echo 'RESPONDE' || echo 'NO RESPONDE')"
echo "✅ SSH:        $(systemctl is-active sshd >/dev/null 2>&1 && echo 'ACTIVO' || echo 'INACTIVO')"

echo ""
echo "=========================================================="
echo "🚀 RESUMEN ARQUITECTURA:"
echo "   • VM Principal (SSH siempre disponible)"
echo "   • NS-EDGE (Router/Firewall @ ${EDGE_IP})"
echo "   • NS-CLIENT (Usuario @ ${CLIENT_IP})"
echo ""
echo "🎯 PUNTOS DE FALLO:"
echo "   • NS-EDGE (iptables, routing, NAT)"
echo "   • NS-CLIENT (configuración de red)"
echo "   • Servicios internos (Web, DB, DNS, Proxy)"
echo ""
echo "🔧 HERRAMIENTAS:"
echo "   lab-status    → Ver estado completo"
echo "   client-diag   → Diagnóstico desde usuario"
echo ""
echo "💡 Comando para empezar: sudo ip netns exec NS-CLIENT bash"
echo "=========================================================="
echo ""