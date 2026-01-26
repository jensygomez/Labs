#!/bin/bash
for i in {1..100}; do
  echo "=== TEST $i/100 ==="
  rm -f /tmp/veth_counter
  ip netns del EDGE-1 CORE-1 2>/dev/null || true
  ip link | grep veth | head -5 | awk '{print $2}' | sed 's/://' | xargs -r ip link delete 2>/dev/null || true
  
  bash script.sh
  
  # Verificación automática
  if ip netns exec EDGE-1 ip link show eth0 2>/dev/null | grep -q UP; then
    echo "✅ PASS $i"
  else
    echo "❌ FAIL $i"
    break
  fi
done
echo "Tests completados: $i"
