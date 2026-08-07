#!/bin/bash
# make-lxd-fleet.sh

SUBNET="10.45.223"
GATEWAY="$SUBNET.1"
NETWORK_NAME="lab-net"

echo "🔧 Configurando red LXD '$NETWORK_NAME' ($SUBNET.0/24)..."
if ! lxc network list -f csv | grep -q "^$NETWORK_NAME,"; then
    lxc network create $NETWORK_NAME ipv4.address=$GATEWAY/24 ipv4.nat=true ipv4.dhcp=false
else
    lxc network set $NETWORK_NAME ipv4.address=$GATEWAY/24 2>/dev/null || true
fi

echo "📦 Configurando perfil base 'profile-lab'..."
lxc profile delete profile-lab 2>/dev/null || true
lxc profile create profile-lab
cat << 'EOF' | lxc profile edit profile-lab
config:
  limits.memory: 512MB
description: Perfil base barebone para los servidores del laboratorio
devices:
  eth0:
    name: eth0
    network: lab-net
    type: nic
  root:
    path: /
    pool: default
    type: disk
name: profile-lab
EOF

echo "🖼️  Verificando imagen de AlmaLinux 9..."
if ! lxc image list -f csv | grep -q "almalinux/9"; then
    lxc image copy images:almalinux/9 local: --alias almalinux9
fi

# 🌟 CLAVE DINÁMICA: Lee tu clave pública actual automáticamente
SSH_KEY=$(cat ~/.ssh/id_lxd_fleet.pub 2>/dev/null || cat ~/.ssh/id_rsa.pub 2>/dev/null || echo "ssh-ed25519 TU_CLAVE_AQUI")

echo "🚀 Desplegando flota de 10 servidores (server01 - server10)..."
for i in {1..10}; do
    NAME=$(printf "server%02d" $i)
    IP="$SUBNET.$((100 + i))"
    
    if lxc info $NAME &>/dev/null; then
        echo "⚠️  $NAME ya existe. Saltando..."
        continue
    fi

    # Cloud-init dinámico (sin comillas en EOF para que expanda $SSH_KEY)
    USER_DATA=$(cat <<EOF
#cloud-config
package_update: true
packages:
  - openssh-server
  - python3
  - python3-pip
  - e2fsprogs
  - bind-utils
  - vim
runcmd:
  - mkdir -p /root/.ssh
  - echo "$SSH_KEY" > /root/.ssh/authorized_keys
  - chmod 700 /root/.ssh
  - chmod 600 /root/.ssh/authorized_keys
  - systemctl enable --now sshd
  - sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  - systemctl restart sshd
  - setenforce 0 || true
  - sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
EOF
)

    # Configuración de red estática persistente (Network Manager la respetará)
    NETWORK_CONFIG=$(cat <<EOF
version: 2
ethernets:
  eth0:
    addresses:
      - $IP/24
    routes:
      - to: default
        via: $GATEWAY
    nameservers:
      addresses:
        - 8.8.8.8
        - 1.1.1.1
EOF
)

    echo "   -> Creando $NAME con IP $IP..."
    lxc launch almalinux9 $NAME --profile profile-lab \
        --config cloud-init.user-data="$USER_DATA" \
        --config cloud-init.network-config="$NETWORK_CONFIG"
done

echo "✅ Flota desplegada. Esperando 20s a que cloud-init termine..."
sleep 20
lxc list
