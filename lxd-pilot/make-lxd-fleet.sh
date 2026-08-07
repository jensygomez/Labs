#!/bin/bash
# make-lxd-fleet.sh

echo "🔧 Usando red LXD 'lab-net' (10.77.77.0/24)..."

echo "📦 Configurando perfil base 'profile-lab'..."
lxc profile delete profile-lab 2>/dev/null
lxc profile create profile-lab
cat profile-lab.yml | lxc profile edit profile-lab

echo "🖼️  Verificando imagen de AlmaLinux 9..."
if ! lxc image alias list -f csv | grep -q "almalinux9"; then
    lxc image alias create almalinux9 b6ad3898b575
fi

SSH_KEY=$(cat ~/.ssh/id_ed25519.pub 2>/dev/null || cat ~/.ssh/id_rsa.pub 2>/dev/null || echo "ssh-ed25519 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+gsGnVlOOJXtW6Wz87hc1CPhOz++T2lCoB6F3Eksbg jensyg@lxd-fleet")

echo "🚀 Desplegando flota de 10 servidores barebone..."
for i in {1..8}; do
    NAME=$(printf "server%02d" $i)
    IP="10.77.77.$i" # IPs van de .1 a .10
    
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
ssh_authorized_keys:
  - $SSH_KEY
users:
  - default
  - name: labadmin
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: wheel, users
    shell: /bin/bash
    lock_passwd: true
ssh_pwauth: false
disable_root: true
runcmd:
  - systemctl enable --now sshd
EOF
)

    echo "   -> Creando $NAME con IP $IP..."
    lxc launch almalinux9 $NAME --profile profile-lab --config cloud-init.user-data="$USER_DATA"
done

echo "✅ Flota desplegada. Esperando 20s a que cloud-init termine..."
sleep 20
echo "📊 Estado actual de la flota:"
lxc list
