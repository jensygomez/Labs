
#!/bin/bash
# make-lxd-fleet.sh

echo "🔧 Configurando red LXD 'lab-net' (192.168.100.0/24)..."
if ! lxc network list -f csv | grep -q "^lab-net,"; then
    lxc network create lab-net ipv4.address=192.168.100.254/24 ipv4.nat=true ipv4.dhcp=false
fi

echo "📦 Configurando perfil base 'profile-lab'..."
lxc profile delete profile-lab 2>/dev/null
lxc profile create profile-lab
cat profile-lab.yml | lxc profile edit profile-lab

echo "🖼️  Verificando imagen de AlmaLinux 9..."
if ! lxc image alias list -f csv | grep -q "almalinux9"; then
    lxc image alias create almalinux9 b6ad3898b575
fi

# Leer tu clave SSH pública para inyectarla
SSH_KEY=$(cat ~/.ssh/id_ed25519.pub 2>/dev/null || cat ~/.ssh/id_rsa.pub 2>/dev/null || echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKWfbAiQX1GhxiPrlZwpfISA7Ni+4b4kVyqQ8ktrC6Yh jensyg@golden-pilot-lab")

echo "🚀 Desplegando flota de 10 servidores barebone..."
for i in {1..10}; do
    NAME=$(printf "server%02d" $i)
    IP="192.168.100.$i"
    
    if lxc info $NAME &>/dev/null; then
        echo "⚠️  $NAME ya existe. Saltando..."
        continue
    fi

    # Generar cloud-init con runcmd usando nmcli (Infalible en AlmaLinux 9)
    USER_DATA=$(cat <<EOF
#cloud-config
package_update: true
packages:
  - openssh-server
  - python3
ssh_authorized_keys:
  - $SSH_KEY
users:
  - default
  - name: labadmin
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: wheel, users
    shell: /bin/bash
    lock_passwd: true
disable_root: true
ssh_pwauth: false
runcmd:
  - systemctl enable --now sshd
  - nmcli con add con-name static-eth0 type ethernet ifname eth0 ipv4.addresses $IP/24 ipv4.gateway 192.168.100.254 ipv4.dns "8.8.8.8,1.1.1.1" ipv4.method manual || true
  - nmcli con up static-eth0 || true
EOF
)

    echo "   -> Creando $NAME con IP $IP..."
    # Lanzamos con el perfil y le inyectamos el user-data dinámico
    lxc launch almalinux9 $NAME --profile profile-lab --config cloud-init.user-data="$USER_DATA"
done

echo "✅ Flota desplegada. Esperando 30s a que nmcli configure las IPs y SSH arranque..."
sleep 30
echo "📊 Estado actual de la flota:"
lxc list
