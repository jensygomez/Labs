#!/bin/bash
# network-engine/lib/firewall.sh
set -Eeuo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/lib/idempotency.sh"  
source "$BASE_DIR/topology/lab.conf"

wensure_firewall(){
  local ns="$1"
  echo "🔒 Configurando FW en $ns"
  ns_exists "$ns" || {echo "❌ Namespace $ns no existe"; return 1;}

  ip netns exec "$ns" nft flush ruleeset 2>/dev/null || true

  # INPUT rules (por namespace)
  local input_rules="${FW_RULES[$ns]:-}"

  ip netns exec "$ns" nft -f <(cat <<EOF
table inet fw_${ns} {

  chain input {
    type filter hook input priority 0; policy drop;
    iifname "lo" accept
    ct state established,related accept
    ${input_rules}
  }

  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
EOF
)
  # Generar Reglas zone-based dinámicas
  for key in "${!FW_ZONES[@]}"; do
    IFS=":" read -r z_ns z_if <<< "$key"
    [[ "$z_ns"  != "$ns" ]]  && continue

    local src_zone="${FW_ZONES[$key]}"

    for key2 in "${FW_ZONES[@]}"; do
      IFS=":" read -r d_ns d_if <<< "$key2"
      [[ "$d_ns" != "$ns" ]] && continue

      local dst_zone="${FW_ZONES[$key2]}"
      local policy="${FW_POLICIES[$src_zone->$dst_zone]:-drop}"

      ip netns exec "$ns" nft add rule inet fw_${ns} forward \
        iifname "$z_if" oifname "$d_if" $policy
    done
  done
}