#!/bin/bash
# make-lxd-fleet.sh - Crea flota con DHCP habilitado

NETWORK_NAME="lxdbr0"
FLEET_PREFIX="server"
FLEET_COUNT=10

# 🕵️ Detectar contenedores existentes
EXISTING=$(lxc list -c n --format csv 2>/dev/null | grep "server" | wc -l)
if [ "$EXISTING" -gt 0 ]; then
    echo "⚠️  Ya existen $EXISTING servidor(es) en el sistema:"
    lxc list -c n | grep "server"
    echo ""
    read -p "¿Deseas eliminarlos antes de crear la nueva flota? (s/N): " clean
    if [[ "$clean" == "s" || "$clean" == "S" ]]; then
        echo "🗑️  Eliminando contenedores existentes..."
        lxc list -c n --format csv | grep "server" | xargs -r lxc delete --force
    else
        echo "Operación cancelada."
        exit 0
    fi
fi

# 🔧 Asegurar que DHCP esté habilitado en lxdbr0
echo "🔧 Verificando red $NETWORK_NAME (DHCP habilitado)..."
DHCP_STATUS=$(lxc network get $NETWORK_NAME ipv4.dhcp 2>/dev/null || echo "true")
if [ "$DHCP_STATUS" == "false" ]; then
    lxc network set $NETWORK_NAME ipv4.dhcp=true
    echo "   ✅ DHCP habilitado en $NETWORK_NAME"
else
    echo "   ✅ DHCP ya estaba habilitado"
fi

# 📦 Perfil base
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
    network: lxdbr0
    type: nic
  root:
    path: /
    pool: default
    type: disk
name: profile-lab
EOF

# 🖼️ Verificar imagen
echo "🖼️  Verificando imagen de AlmaLinux 9..."
if ! lxc image list -f csv | grep -q "almalinux/9"; then
    echo "   -> Descargando imagen (puede tardar)..."
    lxc image copy images:almalinux/9 local: --alias almalinux9
fi

echo "🚀 Desplegando flota de $FLEET_COUNT servidores (con DHCP)..."
for i in $(seq -w 1 $FLEET_COUNT); do
    NAME="${FLEET_PREFIX}${i}"
    
    if lxc info $NAME &>/dev/null; then
        echo "⚠️  $NAME ya existe. Saltando..."
        continue
    fi

    echo "   -> Creando $NAME..."
    lxc launch almalinux9 $NAME --profile profile-lab
done

echo ""
echo "✅ Flota creada con DHCP. Esperando 20s a que obtengan IPs..."
sleep 20
lxc list -c ns | grep "server"
echo ""
echo "💡 Ahora ejecuta: ./setup-fleet.sh para configurar IPs fijas + Golden Base"
