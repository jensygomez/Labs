#!/bin/bash
# make-lxd-fleet.sh

SUBNET="10.45.223"
GATEWAY="$SUBNET.1"
NETWORK_NAME="lxdbr0"  # ← CAMBIO: Usamos lxdbr0 en lugar de lab-net
FLEET_PREFIX="server"
FLEET_COUNT=10

# 🕵️ Detectar contenedores existentes
EXISTING=$(lxc list -c n --format csv 2>/dev/null | grep -v '^$' | wc -l)
if [ "$EXISTING" -gt 0 ]; then
    echo "⚠️  Ya existen $EXISTING contenedor(es) en el sistema:"
    lxc list -c n
    echo ""
    read -p "¿Deseas eliminarlos antes de crear la nueva flota? (s/N): " clean
    if [[ "$clean" == "s" || "$clean" == "S" ]]; then
        echo "🗑️  Eliminando contenedores existentes..."
        lxc list -c n --format csv | grep -v '^$' | xargs -r lxc delete --force
    fi
fi

echo "✅ Usando red LXD existente: $NETWORK_NAME ($SUBNET.0/24)"

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
    network: lxdbr0  # ← CAMBIO: Usamos lxdbr0
    type: nic
  root:
    path: /
    pool: default
    type: disk
name: profile-lab
EOF

echo "🖼️  Verificando imagen de AlmaLinux 9..."
if ! lxc image list -f csv | grep -q "almalinux/9"; then
    echo "   -> Descargando imagen (puede tardar)..."
    lxc image copy images:almalinux/9 local: --alias almalinux9
fi

# 🌟 CLAVE DINÁMICA
SSH_KEY=$(cat ~/.ssh/id_lxd_fleet.pub 2>/dev/null || cat ~/.ssh/id_lab_pilot.pub 2>/dev/null || cat ~/.ssh/id_rsa.pub 2>/dev/null)
if [ -z "$SSH_KEY" ]; then
    echo "❌ ERROR: No se encontró ninguna clave pública en ~/.ssh/"
    echo "   Genera una con: ssh-keygen -t ed25519 -f ~/.ssh/id_lxd_fleet"
    exit 1
fi

echo "🚀 Desplegando flota de $FLEET_COUNT servidores ($FLEET_PREFIX 01-$FLEET_COUNT)..."
for i in $(seq -w 1 $FLEET_COUNT); do
    NAME="${FLEET_PREFIX}${i}"
    IP="$SUBNET.$((100 + 10#$i))"
    
    if lxc info $NAME &>/dev/null; then
        echo "⚠️  $NAME ya existe. Saltando..."
        continue
    fi

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
  - sed -i 's/^PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
  - systemctl restart sshd
  - setenforce 0 || true
  - sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
EOF
)

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
