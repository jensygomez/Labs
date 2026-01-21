#!/bin/bash
# ============================================================================
# LAB BASE CONFIGURATION - SSH + USUARIO + CLOUD-INIT (VERSIÓN ROBUSTA)
# ============================================================================

set -e  # Detener en primer error

echo "=== 🔧 CONFIGURACIÓN BASE DEL LAB - PASO 1/3 ==="
echo "📅 Fecha: $(date)"
echo "🎯 Objetivo: SSH funcional post-reinicio"
echo "================================================"

# ---------------------------------------------------------------------------
# 1️⃣ VERIFICACIÓN ROOT Y SISTEMA
# ---------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then 
    echo "❌ Error: Este script debe ejecutarse como root"
    exit 1
fi

# Detectar si estamos en Rocky Linux
if ! grep -qi "rocky" /etc/os-release; then
    echo "⚠️  Advertencia: Sistema no detectado como Rocky Linux"
    read -p "¿Continuar de todos modos? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# 2️⃣ PREPARAR DIRECTORIOS NECESARIOS
# ---------------------------------------------------------------------------
echo "[1/5] 📁 Preparando directorios del sistema..."

# Crear directorios si no existen
mkdir -p /etc/cloud/cloud.cfg.d
mkdir -p /etc/ssh/sshd_config.d
mkdir -p /home/student/.ssh

echo "   ✅ Directorios creados/verificados"

# ---------------------------------------------------------------------------
# 3️⃣ CONFIGURACIÓN DE CLOUD-INIT (NO INTERFIERA CON SSH)
# ---------------------------------------------------------------------------
echo "[2/5] ☁️  Configurando cloud-init para permitir SSH..."

# Verificar si cloud-init está instalado
if command -v cloud-init >/dev/null 2>&1; then
    echo "   ℹ️  Cloud-init detectado, configurando..."
    
    # Habilitar servicios de cloud-init
    systemctl enable cloud-init cloud-config cloud-final --now 2>/dev/null || echo "   ⚠️  No se pudieron habilitar servicios cloud-init"
    
    # Crear configuración que DESHABILITA el manejo de SSH por cloud-init
    cat > /etc/cloud/cloud.cfg.d/01-no-ssh-management.cfg << 'EOF'
# ============================================================================
# CONFIGURACIÓN CLOUD-INIT PARA LAB 3-TIER
# NO modificar SSH, usuarios existentes, o claves
# ============================================================================

# Deshabilitar completamente el manejo de SSH
ssh_genkeytypes: []
ssh_keys: {}
ssh_deletekeys: false
ssh_pwauth: true

# NO modificar usuarios existentes
manage_etc_hosts: false
manage_resolv_conf: false

# Usuarios - solo para referencia, no crear/modificar
users: []
disable_root: false

# Network - no modificar
network:
  config: disabled

# Módulos a EJECUTAR (quitamos los que manejan SSH)
cloud_init_modules:
  - seed_random
  - bootcmd
  - write-files
  - growpart
  - resizefs
  - set_hostname
  - update_hostname
  - update_etc_hosts
  - ca-certs
  - rsyslog

cloud_config_modules:
  - mounts
  - locale
  - timezone
  - disable-ec2-metadata
  - runcmd

cloud_final_modules:
  - package-update-upgrade-install
  - scripts-per-once
  - scripts-per-boot
  - scripts-per-instance
  - scripts-user
  - keys-to-console
  - phone-home
  - final-message
EOF
    
    echo "   ✅ Cloud-init configurado (sin manejar SSH)"
else
    echo "   ℹ️  Cloud-init no instalado, continuando..."
fi

# ---------------------------------------------------------------------------
# 4️⃣ CONFIGURACIÓN DE USUARIO STUDENT
# ---------------------------------------------------------------------------
echo "[3/5] 👤 Creando usuario student..."

# Crear usuario si no existe
if ! id "student" &>/dev/null; then
    useradd -m -G wheel -s /bin/bash student
    echo "   ✅ Usuario student creado"
else
    echo "   ℹ️  Usuario student ya existe"
fi

# Establecer contraseña (SIEMPRE, por si cloud-init la cambió)
echo "student:redhat" | chpasswd 2>/dev/null || echo "student:redhat" | chpasswd
echo "   🔑 Contraseña establecida: redhat"

# Sudo sin password
echo "student ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/student
chmod 440 /etc/sudoers.d/student
echo "   👑 Sudo sin password configurado"

# ---------------------------------------------------------------------------
# 5️⃣ CONFIGURACIÓN SSH DEFINITIVA (SOBREESCRIBE TODO)
# ---------------------------------------------------------------------------
echo "[4/5] 🔐 Configurando SSH definitivo..."

# 5.1 Configurar .ssh del usuario student
chown student:student /home/student/.ssh
chmod 700 /home/student/.ssh

# Inyectar clave pública ESPECÍFICA para el lab
cat > /home/student/.ssh/authorized_keys << 'EOF'
# ============================================================================
# CLAVES SSH AUTORIZADAS - LAB RHCSA 3-TIER
# ============================================================================

# Clave del lab (para acceso básico)
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByFDKwjMDeGJ5GRhXmZHa75h7dK9JcPHvWWtesSO3/x student@lab-3tier
EOF

chown student:student /home/student/.ssh/authorized_keys
chmod 600 /home/student/.ssh/authorized_keys
echo "   🔑 Clave SSH inyectada en student"

# 5.2 CONFIGURACIÓN SSH PRINCIPAL (más simple y robusta)
cat > /etc/ssh/sshd_config << 'EOF'
# OpenSSH Server Configuration for Lab 3-Tier
Port 22
Protocol 2
ListenAddress 0.0.0.0

# Host Keys
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Authentication Settings
PasswordAuthentication yes
PermitRootLogin yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# Security
LoginGraceTime 120
StrictModes no
MaxAuthTries 6
MaxSessions 20
MaxStartups 10:30:100

# Features
UsePAM yes
X11Forwarding yes
PrintMotd no
PrintLastLog no
TCPKeepAlive yes
ClientAliveInterval 30
ClientAliveCountMax 3
UseDNS no

# Subsystem
Subsystem sftp /usr/libexec/openssh/sftp-server

# Environment
AcceptEnv LANG LC_*
EOF

echo "   📄 Configuración SSH principal establecida"

# 5.3 CONFIGURACIÓN SSH DE ALTA PRIORIDAD
cat > /etc/ssh/sshd_config.d/99-lab-ssh-force.conf << 'EOF'
# Lab 3-Tier SSH Configuration - HIGHEST PRIORITY
# This OVERRIDES all other SSH configurations

PasswordAuthentication yes
PermitRootLogin yes
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
EOF

echo "   🔥 Configuración SSH de alta prioridad creada"

# 5.4 Reiniciar SSH
echo "   🔄 Reiniciando servicio SSH..."
systemctl restart sshd
sleep 3

# 5.5 Verificar
echo "   🔍 Verificando configuración SSH..."
if systemctl is-active --quiet sshd; then
    echo "   ✅ Servicio SSH activo"
else
    echo "   ❌ Servicio SSH inactivo"
    systemctl restart sshd
fi

# ---------------------------------------------------------------------------
# 6️⃣ TEST Y PREPARACIÓN PARA REINICIO
# ---------------------------------------------------------------------------
echo "[5/5] 🧪 Preparando para reinicio..."

# 6.1 Test SSH local SIMPLE
echo -n "   🔄 Test SSH local básico... "
if ssh-keyscan -H localhost 2>/dev/null | grep -q "ssh-"; then
    echo "✅ SSH escuchando"
else
    echo "⚠️  SSH no responde, verificando..."
    netstat -tlnp | grep :22 || ss -tlnp | grep :22
fi

# 6.2 Crear script simple de verificación post-reinicio
cat > /root/check-ssh-after-reboot.sh << 'EOF'
#!/bin/bash
# Simple SSH check after reboot
sleep 10
echo "=== SSH Check after reboot ==="
echo "Date: $(date)"
echo ""
echo "1. SSH Service: $(systemctl is-active sshd)"
echo "2. SSH Config - PasswordAuthentication: $(grep -i '^PasswordAuthentication' /etc/ssh/sshd_config | tail -1)"
echo "3. SSH Config - PermitRootLogin: $(grep -i '^PermitRootLogin' /etc/ssh/sshd_config | tail -1)"
echo ""
echo "To test SSH connection:"
echo "ssh student@$(hostname -I | awk '{print $1}')"
echo "Password: redhat"
EOF

chmod +x /root/check-ssh-after-reboot.sh

# 6.3 Agregar a crontab
if ! crontab -l 2>/dev/null | grep -q "check-ssh-after-reboot"; then
    (crontab -l 2>/dev/null; echo "@reboot /root/check-ssh-after-reboot.sh > /var/log/check-ssh.log 2>&1") | crontab -
    echo "   📅 Check script agregado a crontab (@reboot)"
fi

# ---------------------------------------------------------------------------
# 🎯 RESUMEN FINAL
# ---------------------------------------------------------------------------
echo ""
echo "================================================"
echo "=== 🎯 CONFIGURACIÓN BASE COMPLETADA ==="
echo "================================================"
echo ""
echo "✅ RESUMEN:"
echo "   • Directorios preparados"
echo "   • Cloud-init configurado (si estaba instalado)"
echo "   • Usuario 'student' creado/configurado"
echo "   • Contraseña: redhat"
echo "   • Clave SSH inyectada"
echo "   • Configuración SSH forzada"
echo "   • Check script post-reinicio configurado"
echo ""
echo "🔍 ESTADO ACTUAL:"
echo "   • SSH Service: $(systemctl is-active sshd)"
echo "   • User student: $(id student 2>/dev/null && echo 'Existe' || echo 'No existe')"
echo ""
echo "🚀 SIGUIENTE PASO:"
echo "   REINICIA LA VM Y PRUEBA SSH:"
echo ""
echo "   1. Reiniciar: systemctl reboot"
echo "   2. Esperar 60 segundos"
echo "   3. Conectar: ssh student@$(hostname -I | awk '{print $1}' 2>/dev/null || echo 'IP_DE_LA_VM')"
echo "   4. Contraseña: redhat"
echo ""
echo "📊 LOGS POST-REINICIO:"
echo "   /var/log/check-ssh.log"
echo ""
echo "================================================"
echo "📅 Script ejecutado: $(date)"
echo "================================================"