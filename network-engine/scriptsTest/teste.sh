#!/bin/bash
echo "========================================"
echo " TEST COMPLETO DE LABORATORIO DE RED"
echo "========================================"

# 1. Conectividad interna
echo -e "\n1. CONECTIVIDAD INTERNA:"
targets=("10.255.255.1" "10.255.255.5" "10.255.255.6")
for target in "${targets[@]}"; do
  if ip netns exec CORE-MGMT ping -c 1 -W 1 $target >/dev/null 2>&1; then
    echo "  ✓ CORE-MGMT → $target"
  else
    echo "  ✗ CORE-MGMT → $target"
  fi
done

# 2. Conectividad NAT/Internet
echo -e "\n2. CONECTIVIDAD INTERNET (NAT):"
if ip netns exec CORE-MGMT ping -c 1 -W 1 203.0.113.2 >/dev/null 2>&1; then
  echo "  ✓ CORE-MGMT → INTERNET (203.0.113.2)"
else
  echo "  ✗ CORE-MGMT → INTERNET"
fi

if ip netns exec CORE-SVC ping -c 1 -W 1 203.0.113.2 >/dev/null 2>&1; then
  echo "  ✓ CORE-SVC → INTERNET (203.0.113.2)"
else
  echo "  ✗ CORE-SVC → INTERNET"
fi

# 3. Verificar rutas críticas
echo -e "\n3. RUTAS CRÍTICAS EN EDGE-1:"
ip netns exec EDGE-1 ip route show | grep -E "(10.255.255.[48]/30|default)"

# 4. Verificar NAT
echo -e "\n4. REGLAS NAT EN EDGE-1:"
ip netns exec EDGE-1 iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE

echo -e "\n========================================"
echo " TEST COMPLETADO"
echo "========================================"