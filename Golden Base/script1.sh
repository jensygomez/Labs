#!/bin/bash
# =============================================================================
# PROYECTO: Golden Base Image para Labs 3-Tier (Rocky Linux)
# SCRIPT:  1/5 - Base Layer: "Do One Thing Well" (Unix Philosophy)
# =============================================================================
#
# FILOSOFÍA UNIX APLICADA:
# - KISS: Cada sección una responsabilidad única (SRP).
# - Idempotente: Re-ejecutable sin side-effects (chequeos previos).
# - Modular: Base para scripts 2-5 (namespaces, services, hardening).
# - Transparente: Logs, verificaciones post-reboot, prompt contextual.
#
# OBJETIVO: De instalación limpia → plantilla reproducible para host físico.
#           Prepara ruteo L3, servicios core y usuario lab sin estado residual.
#
# DEPENDENCIAS: Root + Internet (dnf repos).
# SIGUIENTE: script2-network.sh (despliega NS-ROUTER, bridges globales).
# =============================================================================

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
# 2. INSTALAR PAQUETES ESENCIALES (Idempotente + Limpio)
# ---------------------------------------------------------------------------
echo "[1/4] 📦 Actualizando sistema e instalando paquetes base..."

# Upgrade completo (mejor que update --nobest)
dnf upgrade -y

# EPEL: Instalar + refresh (best practice Rocky 9+)
if ! dnf repolist | grep -q epel; then
    dnf install -y epel-release
    dnf upgrade -y  # Refresh post-EPEL
fi

# Paquetes CRÍTICOS para el lab (nftables compat + legacy si legacy iptables)
dnf install -y \
    iproute \
    iptables \
    iptables-nft \
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
    lynx \
    php-fpm \
    php-mysqlnd \
    traceroute

# Cleanup para Golden Image ligera (Unix: least resource)
dnf autoremove -y
dnf clean all

echo "   ✅ Paquetes instalados y sistema limpio"


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
PrintMotd yes
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
# 3.5 CONFIGURACIÓN DE RED ESTÁTICA
# ---------------------------------------------------------------------------
echo "[2.5/4] 🌐 Fijando IP estática..."

# Obtener el nombre de la interfaz principal (la que tiene la ruta por defecto)
IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

if [ -n "$IFACE" ]; then
    nmcli connection modify "$IFACE" \
        ipv4.addresses 192.168.122.100/24 \
        ipv4.gateway 192.168.122.1 \
        ipv4.dns "8.8.8.8,1.1.1.1" \
        ipv4.method manual \
        connection.autoconnect yes

    # Aplicar cambios sin desconectar la sesión actual (importante si corres esto por SSH)
    nmcli connection up "$IFACE"
    echo "   ✅ IP fijada en 192.168.122.211 sobre $IFACE"
else
    echo "   ⚠️ No se detectó interfaz activa para fijar IP"
fi


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
# 5. CONFIGURACIÓN DE PROMPT DINÁMICO PARA NAMESPACES
# ---------------------------------------------------------------------------
echo "[5/5] 🐚 Configurando prompt dinámico..."

# Aplicar tanto para root como para el usuario student
for BASHRC in /root/.bashrc /home/student/.bashrc; do
    cat >> "$BASHRC" << 'EOF'

# --- Lógica de Prompt para Namespaces (Scalable) ---
# Esta función se ejecuta cada vez que el prompt se dibuja
get_ns_prompt() {
    # Detecta si el proceso actual pertenece a un network namespace
    local ns=$(ip netns identify $$ 2>/dev/null)
    if [ -n "$ns" ]; then
        echo "($ns) "
    fi
}

# PS1: [Nombre-NS] Usuario@Host:Directorio$ 
export PS1='$(get_ns_prompt)\u@\h:\w\$ '
EOF
done

echo "   ✅ Prompt configurado para root y student"


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