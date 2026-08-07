#!/bin/bash
# setup-fleet.sh - Configura IP fija + Golden Base + Snapshot

SUBNET="10.45.223"
GATEWAY="$SUBNET.1"
FLEET_PREFIX="server"
FLEET_COUNT=10
SNAPSHOT_NAME="golden-base"

# 🌟 CLAVE DINÁMICA
SSH_KEY=$(cat ~/.ssh/id_lxd_fleet.pub 2>/dev/null || cat ~/.ssh/id_lab_pilot.pub 2>/dev/null || cat ~/.ssh/id_rsa.pub 2>/dev/null)
if [ -z "$SSH_KEY" ]; then
    echo "❌ ERROR: No se encontró ninguna clave pública en ~/.ssh/"
    exit 1
fi

echo "🚀 Configurando Golden Base en toda la flota..."
echo "======================================================="

for i in $(seq -w 1 $FLEET_COUNT); do
    NAME="${FLEET_PREFIX}${i}"
    IP="$SUBNET.$((100 + 10#$i))"
    
    if ! lxc info $NAME &>/dev/null; then
        echo "❌ $NAME no existe. Saltando..."
        continue
    fi
    
    echo ""
    echo "📦 [$NAME] Configurando IP fija $IP + Golden Base..."
    
    # 1. Cambiar IP de DHCP a estática con NetworkManager
    echo "   → Configurando IP estática..."
    lxc exec $NAME -- nmcli con delete "static-eth0" 2>/dev/null || true
    lxc exec $NAME -- nmcli con add type ethernet con-name "static-eth0" ifname eth0 \
        ipv4.addresses "$IP/24" \
        ipv4.gateway "$GATEWAY" \
        ipv4.dns "8.8.8.8,1.1.1.1" \
        ipv4.method manual >/dev/null 2>&1
    lxc exec $NAME -- nmcli con up "static-eth0" >/dev/null 2>&1
    
    # 2. Instalar paquetes Golden Base
    echo "   → Instalando paquetes Golden Base..."
    lxc exec $NAME -- dnf install -y \
        vim wget curl bash-completion htop tmux net-tools bind-utils \
        firewalld audit chrony \
        python3 python3-pip python3-libselinux \
        epel-release \
        tcpdump strace lsof rsync unzip \
        openssh-server >/dev/null 2>&1
    
    # 3. Configurar SSH con clave pública
    echo "   → Configurando SSH..."
    lxc exec $NAME -- bash -c "mkdir -p /root/.ssh"
    lxc exec $NAME -- bash -c "echo '$SSH_KEY' > /root/.ssh/authorized_keys"
    lxc exec $NAME -- bash -c "chmod 700 /root/.ssh"
    lxc exec $NAME -- bash -c "chmod 600 /root/.ssh/authorized_keys"
    lxc exec $NAME -- systemctl enable --now sshd
    lxc exec $NAME -- sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    lxc exec $NAME -- sed -i 's/^PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
    lxc exec $NAME -- systemctl restart sshd
    
    # 4. Configurar SELinux y servicios
    echo "   → Configurando servicios..."
    lxc exec $NAME -- setenforce 0 || true
    lxc exec $NAME -- sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
    lxc exec $NAME -- systemctl enable --now firewalld
    lxc exec $NAME -- systemctl enable --now chronyd
    lxc exec $NAME -- systemctl enable --now auditd
    
    echo "   ✅ $NAME listo"
done

echo ""
echo "======================================================="
echo "📸 Creando snapshot '$SNAPSHOT_NAME' en todos los servidores..."
for i in $(seq -w 1 $FLEET_COUNT); do
    NAME="${FLEET_PREFIX}${i}"
    lxc stop $NAME --force 2>/dev/null
    lxc snapshot $NAME $SNAPSHOT_NAME 2>/dev/null && echo "   ✅ $NAME snapshot creado" || echo "   ⚠️  $NAME snapshot falló"
    lxc start $NAME 2>/dev/null
done

echo ""
echo "🎉 ¡Golden Base completa con snapshot!"
sleep 5
lxc list -c ns | grep "server"
