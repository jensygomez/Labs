#!/bin/bash
# setup-network.sh - Versión mejorada que mantiene tu lógica

SUBNET="10.45.223"
GATEWAY="$SUBNET.1"

echo "=========================================="
echo "🌐 Configurando IPs fijas en toda la flota"
echo "=========================================="

for i in $(seq 1 10); do
  NODE=$(printf "server%02d" $i)
  IP="$SUBNET.$((100 + i))"
  
  echo ""
  echo "=========================================="
  echo "=== Configurando $NODE con IP $IP ==="
  echo "=========================================="

  # 1. Asignar IP estática manual y Gateway
  lxc exec $NODE -- ip addr add $IP/24 dev eth0 2>/dev/null || true
  lxc exec $NODE -- ip route add default via $GATEWAY 2>/dev/null || true

  # 2. Configurar DNS en resolv.conf
  lxc exec $NODE -- rm -f /etc/resolv.conf
  lxc exec $NODE -- bash -c 'printf "nameserver 8.8.8.8\nnameserver 1.1.1.1\n" > /etc/resolv.conf'
  lxc exec $NODE -- chmod 644 /etc/resolv.conf

  # 3. Evitar que NetworkManager modifique el DNS
  lxc exec $NODE -- bash -c 'mkdir -p /etc/NetworkManager/conf.d'
  lxc exec $NODE -- bash -c 'cat <<EOF > /etc/NetworkManager/conf.d/no-dns.conf
[main]
dns=none
EOF'
  lxc exec $NODE -- systemctl restart NetworkManager 2>/dev/null || true

  # 4. Eliminar IPs dinámicas de eth0 dejando solo la estática (MEJORADO)
  echo "   --- Limpiando IPs viejas en $NODE ---"
  
  # OPCIÓN A: Eliminar TODAS las IPs excepto la nueva
  lxc exec $NODE -- bash -c "
    # Obtener todas las IPs de eth0
    ips=\$(ip addr show eth0 | grep 'inet ' | awk '{print \$2}' | grep -v '$IP')
    if [ -n \"\$ips\" ]; then
      echo \"   Eliminando IPs: \$ips\"
      echo \"\$ips\" | xargs -r -I {} ip addr del {} dev eth0
    else
      echo \"   No hay IPs viejas que eliminar\"
    fi
  " 2>/dev/null || true

  # OPCIÓN B (más agresiva): Limpiar todas y luego reasignar
  # lxc exec $NODE -- bash -c "ip addr flush dev eth0" 2>/dev/null || true
  # lxc exec $NODE -- ip addr add $IP/24 dev eth0

  # 5. Verificación de conectividad a Internet
  echo "   --- Verificando conectividad a Internet ---"
  if lxc exec $NODE -- ping -c 2 8.8.8.8 >/dev/null 2>&1; then
    echo "   ✅ OK: $NODE configurado, IP limpia ($IP) y con acceso a Internet."
  else
    echo "   ❌ ERROR: $NODE perdió conectividad a Internet."
    echo "   📋 IPs actuales en $NODE:"
    lxc exec $NODE -- ip addr show eth0
  fi
  echo ""
done

echo ""
echo "✅ Red configurada correctamente"
echo "📊 Estado actual:"
lxc list
