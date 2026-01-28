#!/bin/bash
# network-engine/lib/firewall.sh
set -Eeuo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/lib/idempotency.sh"  # ← AGREGAR ESTA LÍNEA (para ns_exists)
source "$BASE_DIR/topology/lab.conf"

ensure_firewall() {
  local ns="$1"
  echo "🔒 Configurando FW en $ns"
  
  ns_exists "$ns" || { echo "❌ Namespace $ns no existe"; return 1; }  # ← FIX
  
  # Flush idempotente
  ip netns exec "$ns" nft flush ruleset 2>/dev/null || true
  
  # Reglas específicas O default minimal
  local rules="${FW_RULES[$ns]:-}"
  [[ -z "$rules" ]] && rules="ct state related,established accept"
  
  ip netns exec "$ns" nft -f <(cat <<EOF
table inet ${ns}_filter {
  chain input {
    type filter hook input priority 0; policy drop;
    iifname "lo" accept
    ct state related,established accept
    $rules
  }
  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state related,established accept
    ip protocol icmp accept
    iifname "eth0" accept
    iifname "eth1" oifname "eth0" drop
  }
}
EOF
  ) || { echo "❌ FW $ns failed"; return 1; }
  
  echo "✅ FW ${ns} zone-based activo"
}
