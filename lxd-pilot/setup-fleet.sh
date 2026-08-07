#!/bin/bash
# setup-fleet.sh - Versión que lee del inventario

INVENTORY_FILE="inventory.ini"

if [ ! -f "$INVENTORY_FILE" ]; then
    echo "❌ ERROR: No se encontró el archivo de inventario '$INVENTORY_FILE'"
    exit 1
fi

# 🌟 CLAVE DINÁMICA
PUB_KEY_PATH=$(grep 'ssh_public_key_path' "$INVENTORY_FILE" | cut -d'=' -f2 | tr -d ' "' | sed "s|~|$HOME|")
SSH_KEY=$(cat "$PUB_KEY_PATH" 2>/dev/null)

if [ -z "$SSH_KEY" ]; then
    echo "❌ ERROR: No se encontró la clave pública en $PUB_KEY_PATH"
    exit 1
fi

SUBNET="10.45.223"
GATEWAY="$SUBNET.1"
SNAPSHOT_NAME="golden-base"

# =============================================
# PASO 0: Verificar el HOST (Laptop)
# =============================================
echo "🔧 Verificando configuración del HOST (laptop)..."
if [ "$(cat /proc/sys/net/ipv4/ip_forward)" != "1" ]; then
    echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-lxd-forwarding.conf > /dev/null
    sudo sysctl -p /etc/sysctl.d/99-lxd-forwarding.conf > /dev/null
fi

if ! sudo iptables -t nat -L POSTROUTING -n 2>/dev/null | grep -q "MASQUERADE.*$SUBNET"; then
    sudo iptables -t nat -A POSTROUTING -s $SUBNET.0/24 ! -d $SUBNET.0/24 -j MASQUERADE
fi
if ! sudo iptables -L FORWARD -n 2>/dev/null | grep -q "lxdbr0.*ACCEPT"; then
    sudo iptables -A FORWARD -i lxdbr0 -j ACCEPT
    sudo iptables -A FORWARD -o lxdbr0 -j ACCEPT
fi
echo "   ✅ Host configurado correctamente"

# =============================================
# PASO 1: Leer servidores del inventario
# =============================================
echo ""
echo "🚀 Configurando Golden Base en toda la flota..."
echo "======================================================="

# Leer los servidores del inventario
grep -E '^server[0-9]+' "$INVENTORY_FILE" | while read -r line; do
    NODE=$(echo "$line" | awk '{print $1}')
    # Extraer el número del servidor (server01 -> 1)
    NUM=$(echo "$NODE" | grep -oP '[0-9]+')
    # Calcular IP con la misma lógica probada
    IP="$SUBNET.$((100 + NUM))"
    
    if ! lxc info "$NODE" &>/dev/null; then
        echo "❌ $NODE no existe en LXD. Saltando..."
        continue
    fi

    echo ""
    echo "=========================================="
    echo "=== Configurando $NODE con IP $IP ==="
    echo "=========================================="

    # 1. Asignar IP estática manual y Gateway
    lxc exec "$NODE" -- ip addr add "$IP/24" dev eth0 2>/dev/null || true
    lxc exec "$NODE" -- ip route add default via "$GATEWAY" 2>/dev/null || true

    # 2. Configurar DNS en resolv.conf
    lxc exec "$NODE" -- rm -f /etc/resolv.conf
    lxc exec "$NODE" -- bash -c 'printf "nameserver 8.8.8.8\nnameserver 1.1.1.1\n" > /etc/resolv.conf'
    lxc exec "$NODE" -- chmod 644 /etc/resolv.conf

    # 3. Evitar que NetworkManager modifique el DNS
    lxc exec "$NODE" -- bash -c 'mkdir -p /etc/NetworkManager/conf.d'
    lxc exec "$NODE" -- bash -c 'cat <<EOF > /etc/NetworkManager/conf.d/no-dns.conf
[main]
dns=none
EOF'
    lxc exec "$NODE" -- systemctl restart NetworkManager 2>/dev/null || true

    # 4. Instalar paquetes Golden Base
    echo "   → Instalando paquetes base..."
    lxc exec "$NODE" -- dnf install -y epel-release 2>/dev/null || true
    lxc exec "$NODE" -- dnf install -y \
        openssh-server python3 e2fsprogs \
        vim wget curl bash-completion htop tmux \
        net-tools bind-utils firewalld audit chrony \
        python3-pip python3-libselinux tcpdump strace \
        lsof rsync unzip 2>/dev/null || true

    # 5. Habilitar SSH y permitir Root Login
    lxc exec "$NODE" -- systemctl enable --now sshd
    lxc exec "$NODE" -- sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    lxc exec "$NODE" -- sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
    lxc exec "$NODE" -- systemctl restart sshd

    # 6. Configurar clave pública SSH
    lxc exec "$NODE" -- bash -c "mkdir -p /root/.ssh"
    lxc exec "$NODE" -- bash -c "echo '$SSH_KEY' > /root/.ssh/authorized_keys"
    lxc exec "$NODE" -- bash -c "chmod 700 /root/.ssh"
    lxc exec "$NODE" -- bash -c "chmod 600 /root/.ssh/authorized_keys"

    # 7. Configurar servicios adicionales
    lxc exec "$NODE" -- setenforce 0 2>/dev/null || true
    lxc exec "$NODE" -- sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config 2>/dev/null || true
    lxc exec "$NODE" -- systemctl enable --now firewalld 2>/dev/null || true
    lxc exec "$NODE" -- systemctl enable --now chronyd 2>/dev/null || true
    lxc exec "$NODE" -- systemctl enable --now auditd 2>/dev/null || true

    # 8. Eliminar IPs dinámicas de eth0 dejando solo la estática
    echo "   --- Limpiando IPs viejas en $NODE ---"
    lxc exec "$NODE" -- bash -c "ip addr show eth0 | grep 'inet ' | awk '{print \$2}' | grep -v '$IP' | xargs -r -I {} ip addr del {} dev eth0" 2>/dev/null || true

    # 9. Verificación de conectividad a Internet
    echo "   --- Verificando conectividad a Internet ---"
    if lxc exec "$NODE" -- ping -c 2 8.8.8.8 >/dev/null 2>&1; then
        echo "   >>> OK: $NODE configurado, IP limpia ($IP) y con acceso a Internet."
    else
        echo "   >>> ERROR: $NODE perdió conectividad a Internet."
        echo "   📋 IPs actuales en $NODE:"
        lxc exec "$NODE" -- ip addr show eth0
    fi
    echo ""
done

# =============================================
# PASO 2: Crear snapshots
# =============================================
echo ""
echo "======================================================="
echo "📸 Creando snapshot '$SNAPSHOT_NAME'..."

grep -E '^server[0-9]+' "$INVENTORY_FILE" | while read -r line; do
    NODE=$(echo "$line" | awk '{print $1}')
    
    echo "   → Procesando $NODE..."
    lxc stop "$NODE" --force 2>/dev/null
    
    # Eliminar snapshot previo si existe
    lxc delete "$NODE/$SNAPSHOT_NAME" 2>/dev/null || true
    
    # Crear snapshot
    if lxc snapshot "$NODE" "$SNAPSHOT_NAME" 2>/dev/null; then
        echo "   ✅ $NODE"
    else
        echo "   ⚠️  $NODE falló"
    fi
    
    lxc start "$NODE" 2>/dev/null
done

echo ""
echo "🎉 ¡Golden Base completa con Snapshot!"
echo ""
echo "📊 Resumen final:"
lxc list
