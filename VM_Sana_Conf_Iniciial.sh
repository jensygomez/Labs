#!/bin/bash
# ============================================================================
# 🔥 SCRIPT DE CONFIGURACIÓN VM BASE SANA - Rocky 9.7 🔥
# ============================================================================
# Objetivo: Configurar la VM para laboratorio de Incident Response
# Incluye actualización del sistema, instalación de paquetes base y servicios.
# Autor: Jensy
# ============================================================================


echo "=== DIAGRAMA DE CONECTIVIDAD ==="
echo ""
echo "           [Servidor Principal]"
echo "                  ↓ enp1s0"
echo "           ┌─────────────────┐"
echo "           │  Firewall Rules │"
echo "           └─────────────────┘"
echo "         ↙       ↓       ↘       ↙"
echo "[dummy-web] [dummy-db] [dummy-proxy] [dummy-dns]"
echo " 10.10.10.10 10.10.20.10 10.10.30.10 10.10.40.10"
echo "    nginx     mariadb      squid      dnsmasq"
echo ""
echo "=== FLUJO DE APLICACIÓN ==="
echo "1. DNS: web.lab.local → 10.10.10.10"
echo "2. Proxy: 10.10.30.10:3128"
echo "3. Web: 10.10.10.10 → DB:10.10.20.10"


set -euo pipefail

echo "=== INICIO: Actualización y preparación de paquetes base ==="
sleep 2

# ------------------------------
# 1️⃣ Actualizar sistema y paquetes base
# ------------------------------
dnf update -y

dnf install -y \
  epel-release \
  nginx \
  mariadb-server \
  squid \
  dnsmasq \
  firewalld \
  bind-utils \
  net-tools \
  iproute \
  policycoreutils-python-utils

echo "[+] Sistema actualizado y paquetes base instalados"
sleep 2

# ------------------------------
# 2️⃣ Habilitar servicios base (pero no iniciar todos aún)
# ------------------------------
systemctl enable nginx mariadb squid dnsmasq firewalld
systemctl start firewalld
echo "[+] Servicios habilitados; firewalld iniciado"
sleep 2

# ------------------------------
# 3️⃣ Crear script de interfaces dummy
# ------------------------------
cat << 'EOF' > /usr/local/sbin/lab-dummy-net.sh
#!/bin/bash
# Crear interfaces dummy
ip link add dummy-web type dummy
ip addr add 10.10.10.10/24 dev dummy-web
ip link set dummy-web up

ip link add dummy-db type dummy
ip addr add 10.10.20.10/24 dev dummy-db
ip link set dummy-db up

ip link add dummy-proxy type dummy
ip addr add 10.10.30.10/24 dev dummy-proxy
ip link set dummy-proxy up

ip link add dummy-dns type dummy
ip addr add 10.10.40.10/24 dev dummy-dns
ip link set dummy-dns up
EOF

chmod +x /usr/local/sbin/lab-dummy-net.sh
echo "[+] Script dummy creado"
sleep 2

# ------------------------------
# 4️⃣ Crear servicio systemd para persistencia de interfaces
# ------------------------------
cat << 'EOF' > /etc/systemd/system/lab-dummy-net.service
[Unit]
Description=Lab Dummy Interfaces
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/lab-dummy-net.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now lab-dummy-net
echo "[+] Servicio lab-dummy-net habilitado y ejecutado"
sleep 3

# ------------------------------
# 5️⃣ Configurar firewall
# ------------------------------
for i in dummy-web dummy-db dummy-proxy dummy-dns; do
    firewall-cmd --permanent --zone=trusted --add-interface=$i
done
firewall-cmd --reload
echo "[+] Firewall configurado con interfaces dummy en zona trusted"
sleep 2

# ------------------------------
# 6️⃣ Configurar Nginx
# ------------------------------
cat << 'EOF' > /etc/nginx/conf.d/lab.conf
server {
    listen 10.10.10.10:80 default_server;
    server_name web.lab.local;

    location / {
        add_header Content-Type text/plain;
        return 200 "WEB OK - Base Sana\n";
    }
}
EOF

nginx -t
systemctl start nginx
echo "[+] Nginx configurado y activo"
sleep 2


# ------------------------------
# 7️⃣ Configurar MariaDB
# ------------------------------
systemctl start mariadb

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS labdb;
USE labdb;
CREATE TABLE IF NOT EXISTS incidents (
  id INT PRIMARY KEY,
  service VARCHAR(20),
  status VARCHAR(10)
);
INSERT INTO incidents (id, service, status)
VALUES
  (1,'WEB','UP'),
  (2,'DB','UP'),
  (3,'DNS','UP'),
  (4,'PROXY','UP')
ON DUPLICATE KEY UPDATE service=VALUES(service), status=VALUES(status);

-- ⚠ Crear usuario labuser con acceso desde toda la subred 10.10.x.x
CREATE USER IF NOT EXISTS 'labuser'@'10.10.%' IDENTIFIED BY 'labpass';
GRANT ALL PRIVILEGES ON labdb.* TO 'labuser'@'10.10.%';
FLUSH PRIVILEGES;
EOF

echo "[+] MariaDB configurada con tabla de incidentes y usuario labuser con acceso interno"
sleep 2



# ------------------------------
# 8️⃣ Configurar dnsmasq
# ------------------------------
cat << 'EOF' > /etc/dnsmasq.d/lab.conf
listen-address=10.10.40.10
bind-interfaces
domain-needed
bogus-priv
expand-hosts
address=/web.lab.local/10.10.10.10
EOF

systemctl start dnsmasq
echo "[+] dnsmasq configurado y activo"
sleep 2

# ------------------------------
# 9️⃣ Configurar Squid
# ------------------------------
cat << 'EOF' > /etc/squid/squid.conf
http_port 10.10.30.10:3128
dns_nameservers 10.10.40.10
acl localnet src 10.10.0.0/16
http_access allow localnet
http_access deny all
access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log
EOF

systemctl start squid
echo "[+] Squid configurado y activo"
sleep 3

# ------------------------------
# 🔟 SELinux: permitir conexiones de Squid
# ------------------------------
setsebool -P squid_connect_any on
echo "[+] SELinux configurado para permitir conexión de Squid"
sleep 1


# ------------------------------
# 11️⃣ Verificación final
# ------------------------------
echo "=== VERIFICACIÓN ==="
echo "Interfaces:"
ip a | grep dummy
echo "Firewall:"
firewall-cmd --get-active-zones
echo "Servicios:"
systemctl is-active nginx squid dnsmasq mariadb
echo "DNS:"
dig @10.10.40.10 web.lab.local
echo "WEB:"
export http_proxy=http://10.10.30.10:3128
curl -s http://web.lab.local
echo "MariaDB remoto:"
mysql -u labuser -plabpass -h 10.10.20.10 labdb -e "SELECT * FROM incidents;"
echo "Base Sana configurada ✅"
sleep 2
echo "=== FIN DEL SCRIPT ==="
