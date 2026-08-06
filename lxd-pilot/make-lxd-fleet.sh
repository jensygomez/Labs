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

echo "🚀 Desplegando flota de 10 servidores barebone..."
for i in {1..10}; do
    NAME=$(printf "server%02d" $i)
    IP="192.168.100.$i"
    
    if lxc info $NAME &>/dev/null; then
        echo "⚠️  $NAME ya existe. Saltando..."
        continue
    fi

    # Generar YAML de red con indentación perfecta usando Here-Doc
    NETWORK_CONFIG=$(cat <<EOF
version: 2
ethernets:
  eth0:
    addresses:
      - $IP/24
    routes:
      - to: default
        via: 192.168.100.254
    nameservers:
      addresses:
        - 8.8.8.8
        - 1.1.1.1
EOF
)

    echo "   -> Creando $NAME con IP $IP..."
    lxc launch almalinux9 $NAME --profile profile-lab --config cloud-init.network-config="$NETWORK_CONFIG"
done

echo "✅ Flota desplegada. Esperando 20s a que cloud-init configure la red..."
sleep 20
echo "📊 Estado actual de la flota:"
lxc list
