#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux)
# SCRIPT:   1 de 5 - Cimentación y Preparación del Sistema (Base Layer)
# ============================================================================
#
# OBJETIVO PRINCIPAL:
#   Transformar una instalación limpia de Rocky Linux en una plantilla (Golden
#   Image) que servirá como host físico para una arquitectura 3-Tier.
#
# ACCIONES REALIZADAS EN ESTE SCRIPT (FASE 1):
#   1. Actualización integral de paquetes y habilitación de repositorio EPEL.
#   2. Instalación de utilidades de red y diagnóstico (tcpdump, nmap, net-tools).
#   3. Despliegue de servicios Core (MariaDB, Nginx, SSH) que serán aislados
#      en fases posteriores.
#   4. Creación del usuario de laboratorio 'student' con privilegios Sudo.
#   5. Habilitación de IP Forwarding a nivel de Kernel (Preparación para Ruteo).
#
# VÍNCULO CON EL SCRIPT 2 (PRÓXIMA FASE):
#   Este script sienta las bases de software para que el SCRIPT 2 pueda:
#   - Segmentar el tráfico mediante Network Namespaces (NS-CLIENT, NS-EDGE, etc).
#   - Utilizar las herramientas instaladas aquí para validar la conectividad.
#   - Implementar la persistencia mediante Systemd, asegurando que la 
#     configuración de red sea resiliente a reinicios.
#
# REQUISITOS:
#   - Ejecución como Root.
#   - Acceso a Internet para descarga de dependencias.
# ============================================================================
set -e

# (Aquí continúa el resto de tu código...)

echo "=== 📦 SCRIPT 1: CONFIGURACIÓN BASE ==="
echo "📅 Fecha: $(date)"
echo "========================================="

# ---------------------------------------------------------------------------
# 1. VERIFICACIÓN
# ---------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then 
    echo "❌ Ejecutar como root: sudo $0"
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. INSTALAR PAQUETES ESENCIALES
# ---------------------------------------------------------------------------
echo "[1/4] 📦 Instalando paquetes base..."
dnf update -y --nobest

# Instalar EPEL si no existe
if ! dnf repolist | grep -q epel; then
    dnf install -y epel-release
fi

# Paquetes CRÍTICOS para el lab
dnf install -y \
    iproute \
    iptables \
    iptables-services \
    nginx \
    mariadb-server \
    mariadb \
    dnsmasq \
    bind-utils \
    net-tools \
    curl \
    wget \
    vim-enhanced \
    tree \
    tcpdump \
    nmap \
    htop \
    cronie \
    openssh-server \
    openssh-clients \
    lynx

echo "   ✅ Paquetes instalados"

# ---------------------------------------------------------------------------
# 3. CONFIGURAR SSH Y USUARIO
# ---------------------------------------------------------------------------
echo "[2/4] 🔐 Configurando SSH y usuario..."

# Crear usuario student
if ! id "student" &>/dev/null; then
    useradd -m -G wheel -s /bin/bash student
fi
echo "student:redhat" | chpasswd
echo "student ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/student
chmod 440 /etc/sudoers.d/student

# Configuración SSH SIMPLE Y DIRECTA
cat > /etc/ssh/sshd_config << 'EOF'
Port 22
Protocol 2
ListenAddress 0.0.0.0

# Host Keys
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Authentication
PasswordAuthentication yes
PermitRootLogin yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no

# Security
LoginGraceTime 120
StrictModes no
MaxAuthTries 6
MaxSessions 20

# Features
UsePAM yes
X11Forwarding yes
PrintMotd no
TCPKeepAlive yes
UseDNS no

# Subsystem
Subsystem sftp /usr/libexec/openssh/sftp-server
EOF

# Clave SSH para student
mkdir -p /home/student/.ssh
cat > /home/student/.ssh/authorized_keys << 'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByFDKwjMDeGJ5GRhXmZHa75h7dK9JcPHvWWtesSO3/x student@lab-3tier
EOF
chown -R student:student /home/student/.ssh
chmod 700 /home/student/.ssh
chmod 600 /home/student/.ssh/authorized_keys

# Reiniciar SSH
systemctl restart sshd
systemctl enable sshd

echo "   ✅ SSH y usuario configurados"

# ---------------------------------------------------------------------------
# 4. CONFIGURACIÓN BÁSICA DEL SISTEMA
# ---------------------------------------------------------------------------
echo "[3/4] ⚙️  Configuración básica del sistema..."

# Habilitar IP forwarding para futuros scripts
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/99-lab.conf
sysctl -p /etc/sysctl.d/99-lab.conf

# Crear directorios base
mkdir -p /etc/lab-configs
mkdir -p /usr/share/nginx/html

# Deshabilitar firewalld (usaremos iptables directo)
systemctl stop firewalld 2>/dev/null || true
systemctl disable firewalld 2>/dev/null || true

# Habilitar servicios base
systemctl enable --now mariadb
systemctl enable --now crond

echo "   ✅ Sistema base configurado"

# ---------------------------------------------------------------------------
# 5. CREAR SCRIPT DE VERIFICACIÓN POST-REINICIO
# ---------------------------------------------------------------------------
echo "[4/4] 📋 Creando verificación post-reinicio..."

cat > /root/check-post-reboot.sh << 'EOF'
#!/bin/bash
echo "=== ✅ VERIFICACIÓN POST-REINICIO ==="
echo "Fecha: $(date)"
echo ""
echo "1. Servicios:"
echo "   SSH: $(systemctl is-active sshd)"
echo "   MariaDB: $(systemctl is-active mariadb)"
echo ""
echo "2. Usuario student:"
id student 2>/dev/null && echo "   ✅ Existe" || echo "   ❌ No existe"
echo ""
echo "3. SSH disponible en:"
ip -o addr show scope global | awk '{print $2, $4}' | head -3
echo ""
echo "🎯 Para continuar: Ejecutar script2-network.sh como root"
EOF

chmod +x /root/check-post-reboot.sh

# Agregar a crontab
(crontab -l 2>/dev/null; echo "@reboot /root/check-post-reboot.sh > /var/log/lab-post-reboot.log 2>&1") | crontab -

echo "   ✅ Script de verificación creado"

# ---------------------------------------------------------------------------
# RESUMEN
# ---------------------------------------------------------------------------
echo ""
echo "========================================="
echo "✅ SCRIPT 1 COMPLETADO"
echo "========================================="
echo ""
echo "📊 RESUMEN:"
echo "   • Paquetes instalados: iproute, nginx, mariadb, dnsmasq, etc."
echo "   • Usuario: student/redhat (sudo sin password)"
echo "   • SSH: PasswordAuthentication=yes, PermitRootLogin=yes"
echo "   • MariaDB: Instalado y activo"
echo "   • Verificación: Configurada (@reboot)"
echo ""
echo "🚀 PRÓXIMOS PASOS:"
echo "   1. Reiniciar: systemctl reboot"
echo "   2. Verificar SSH: ssh student@IP_DE_LA_VM"
echo "   3. Ejecutar: sudo script2-network.sh"
echo ""
echo "🔍 Logs post-reinicio: /var/log/lab-post-reboot.log"
echo "========================================="