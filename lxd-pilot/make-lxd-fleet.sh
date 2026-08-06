#!/bin/bash
# make-lxd-fleet.sh

echo "🔧 Configurando red LXD 'lab-net' (192.168.100.0/24)..."
# Crear red si no existe (DHCP desactivado para forzar IPs estáticas)
lxc network list -f csv | grep -q "^lab-net," || lxc network create lab-net ipv4.address=192.168.100.254/24 ipv4.nat=true ipv4.dhcp=false

echo "📦 Importando perfil base..."
lxc profile copy profile-lab default 2>/dev/null || lxc profile create profile-lab
lxc profile edit profile-lab < profile-lab.yml 2>/dev/null || cat profile-lab.yml | lxc profile create profile-lab

echo "🚀 Desplegando flota de 10 servidores barebone..."
for i in {1..10}; do
    NAME=$(printf "server%02d" $i)
    IP="192.168.100.$i"
    
    # Verificar si ya existe
    if lxc info $NAME &>/dev/null; then
        echo "⚠️  $NAME ya existe. Saltando..."
        continue
    fi

    # Configurar cloud-init para asignar IP estática
    NETWORK_CONFIG="version: 2
ethernets:
  eth0:
    addresses:
      - $IP/24"

    echo "   -> Creando $NAME con IP $IP..."
    lxc launch almalinux9 $NAME --profile profile-lab --config cloud-init.network-config="$NETWORK_CONFIG"
done

echo "✅ Flota desplegada. Esperando 10s a que cloud-init termine de configurar las IPs..."
sleep 10
echo "📊 Estado actual de la flota:"
lxc list
