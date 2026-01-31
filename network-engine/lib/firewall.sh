#!/bin/bash
# network-engine/lib/firewall.sh
set -Eeuo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/lib/idempotency.sh"  
source "$BASE_DIR/topology/lab.conf"

ensure_firewall() {
  local ns="$1"
  echo "🔒 Configurando FW en $ns"

  ns_exists "$ns" || { echo "❌ Namespace $ns no existe"; return 1; }

  # SOLO borrar nuestra tabla específica, NO todo el ruleset
  ip netns exec "$ns" nft delete table inet fw_${ns} 2>/dev/null || true

  local ruleset=""
  local input_rules="${FW_RULES[$ns]:-}"

  ruleset+="table inet fw_${ns} {\n"
  ruleset+="  chain input {\n"
  ruleset+="    type filter hook input priority 0; policy drop;\n"
  ruleset+="    iifname \"lo\" accept\n"
  ruleset+="    ct state established,related accept\n"
  [[ -n "$input_rules" ]] && ruleset+="    $input_rules\n"
  ruleset+="  }\n\n"

  ruleset+="  chain forward {\n"
  ruleset+="    type filter hook forward priority 0; policy drop;\n"
  ruleset+="    ct state established,related accept\n"

  for key in "${!FW_ZONES[@]}"; do
    IFS=":" read -r src_ns src_if <<< "$key"
    [[ "$src_ns" != "$ns" ]] && continue
    src_zone="${FW_ZONES[$key]}"

    for key2 in "${!FW_ZONES[@]}"; do
      IFS=":" read -r dst_ns dst_if <<< "$key2"
      [[ "$dst_ns" != "$ns" ]] && continue
      dst_zone="${FW_ZONES[$key2]}"

      policy="${FW_POLICIES["$src_zone->$dst_zone"]:-drop}"

      ruleset+="    iifname \"$src_if\" oifname \"$dst_if\" $policy\n"
    done
  done

  ruleset+="  }\n"
  ruleset+="}\n"

  echo -e "$ruleset" | ip netns exec "$ns" nft -f -

  echo "✅ FW ${ns} zone-based activo"
}