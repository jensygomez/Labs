#!/bin/bash
# ============================================================================
# 🔥 SCRIPT DE CONFIGURACIÓN VM BASE SANA - Rocky 9.7 🔥
# ============================================================================
# Objetivo: Configurar la VM para laboratorio de Incident Response
# Incluye actualización del sistema, cloud-init, paquetes base y servicios.
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
# 0️⃣ INSTALAR Y CONFIGURAR CLOUD-INIT (NUEVO - CRÍTICO)
# ------------------------------
echo "=== 🚀 CONFIGURANDO CLOUD-INIT ==="
dnf install -y cloud-init cloud-utils-growpart qemu-guest-agent

# Habilitar servicios cloud-init
systemctl enable cloud-init-local cloud-init cloud-config cloud-final qemu-guest-agent

# Configurar datasource NoCloud para libvirt
cat > /etc/cloud/cloud.cfg.d/90_libvirt.cfg <<'EOF'
datasource_list: [ NoCloud, None ]
disable_ec2_metadata: true
EOF

# Limpiar estado para clones limpios
rm -rf /var/lib/cloud/* /var/log/cloud-init*

echo "[+] Cloud-init instalado y configurado para labs"
sleep 2



# ------------------------------
# 0️⃣1️⃣ SSH + STUDENT + SUDO (CRÍTICO - NUNCA MÁS PROBLEMAS)
# ------------------------------
echo "=== 🔑 SSH + STUDENT + SUDO ==="

# Limpiar sudoers rotos
rm -f /etc/sudoers.d/student

# Crear/actualizar student
useradd -m -G wheel -s /bin/bash student 2>/dev/null || true

# SUDOERS con visudo (syntax perfecto)
echo "student ALL=(ALL) NOPASSWD:ALL" | EDITOR="tee" visudo -f /etc/sudoers.d/student

# Clave RHCSA para student Y root
RHCSA_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByFDKwjMDeGJ5GRhXmZHa75h7dK9JcPHvWWtesSO3/x RHCSA Storage Labs"

for user in student root; do
    mkdir -p "/home/$user/.ssh"
    echo "$RHCSA_KEY" > "/home/$user/.ssh/authorized_keys"
    chown -R "$user:$user" "/home/$user/.ssh"
    chmod 700 "/home/$user/.ssh"
    chmod 600 "/home/$user/.ssh/authorized_keys"
done

# SSH - FORZAR EN TODOS lados
echo "PasswordAuthentication yes" > /etc/ssh/sshd_config.d/99-labs.conf
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config.d/99-labs.conf
sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

systemctl restart sshd
echo "[+] SSH student/root + clave RHCSA + sudo ✅"
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
  policycoreutils-python-utils \
  qemu-guest-agent

echo "[+] Sistema actualizado y paquetes base instalados"
sleep 2

# ------------------------------
# 2️⃣ Habilitar servicios base (pero no iniciar todos aún)
# ------------------------------
systemctl enable nginx mariadb squid dnsmasq firewalld cloud-init-local cloud-init cloud-config cloud-final qemu-guest-agent
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

CREATE USER IF NOT EXISTS 'labuser'@'10.10.%' IDENTIFIED BY 'labpass';
GRANT ALL PRIVILEGES ON labdb.* TO 'labuser'@'10.10.%';
FLUSH PRIVILEGES;
EOF

echo "[+] MariaDB configurada con tabla de incidentes y usuario labuser"
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
# 1️⃣1️⃣ Regenerar initramfs con cloud-init
# ------------------------------
dracut -f
echo "[+] Initramfs regenerado con cloud-init"

# ------------------------------
# 1️⃣2️⃣ Usuario student para labs
# ------------------------------
useradd -m -G wheel -s /bin/bash student
echo "student ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/student
usermod -aG wheel student
echo "[+] Usuario student creado para labs"



# ------------------------------
# 1️⃣3️⃣ USUARIO STUDENT + SSH (PERMANENTE)
# ------------------------------
echo "=== 🚀 CONFIGURANDO USUARIO STUDENT + SSH ==="

# Crear usuario student
useradd -m -G wheel -s /bin/bash student

# Copiar clave pública desde HOST (montar via virtiofs o copiar manual)
mkdir -p /home/student/.ssh
cat > /home/student/.ssh/authorized_keys <<'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByFDKwjMDeGJ5GRhXmZHa75h7dK9JcPHvWWtesSO3/x RHCSA Storage Labs
EOF

# Permisos correctos
chown -R student:student /home/student/.ssh
chmod 700 /home/student/.ssh
chmod 600 /home/student/.ssh/authorized_keys

# Habilitar password auth + root login
sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# Sudo sin contraseña
echo "student ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/student
chmod 440 /etc/sudoers.d/student

systemctl restart sshd
echo "[+] Usuario student + SSH configurado PERMANENTEMENTE"

# Abrir SSH en firewall (CRÍTICO)
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# Dummy interfaces también en trusted
firewall-cmd --permanent --zone=trusted --add-interface=enp1s0
firewall-cmd --reload


# ------------------------------
# 1️⃣3️⃣ Verificación final
# ------------------------------
echo "=== VERIFICACIÓN ==="
echo "Cloud-init:"
rpm -q cloud-init
cloud-init --version
echo "Interfaces:"
ip a | grep dummy
echo "Firewall:"
firewall-cmd --get-active-zones
echo "Servicios:"
systemctl is-active nginx squid dnsmasq mariadb cloud-init
echo "DNS:"
dig @10.10.40.10 web.lab.local
echo "WEB:"
export http_proxy=http://10.10.30.10:3128
curl -s http://web.lab.local
echo "MariaDB remoto:"
mysql -u labuser -plabpass -h 10.10.20.10 labdb -e "SELECT * FROM incidents;"
echo ""
echo "🚀 VM BASE SANA + CLOUD-INIT LISTA PARA LABS ✅"
echo "=== FIN DEL SCRIPT ==="
