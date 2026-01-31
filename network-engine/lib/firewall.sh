#!/bin/bash
# network-engine/lib/firewall.sh
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/lib/idempotency.sh"  

ensure_firewall() {
  local ns="$1"
  echo "🔒 Configurando FW en $ns"

  ns_exists "$ns" || { echo "❌ Namespace $ns no existe"; return 1; }

  ip netns exec "$ns" nft delete table inet fw_${ns} 2>/dev/null || true

  local ruleset=""
  local input_rules="${FW_RULES[$ns]:-}"

  ruleset+="table inet fw_${ns} {\n"
  
  ruleset+="  chain input {\n"
  ruleset+="    type filter hook input priority 0; policy drop;\n"
  ruleset+="    iifname \"lo\" accept\n"
  # Añadimos counter aquí para ver el tráfico de retorno al router
  ruleset+="    ct state established,related counter accept\n"
  [[ -n "$input_rules" ]] && ruleset+="    $input_rules\n"
  ruleset+="  }\n\n"

  ruleset+="  chain forward {\n"
  ruleset+="    type filter hook forward priority 0; policy drop;\n"
  # Añadimos counter aquí para ver el grueso del tráfico pasando
  ruleset+="    ct state established,related counter accept\n"

  for key in "${!FW_ZONES[@]}"; do
    IFS=":" read -r src_ns src_if <<< "$key"
    [[ "$src_ns" != "$ns" ]] && continue
    src_zone="${FW_ZONES[$key]}"

    for key2 in "${!FW_ZONES[@]}"; do
      IFS=":" read -r dst_ns dst_if <<< "$key2"
      [[ "$dst_ns" != "$ns" ]] && continue
      dst_zone="${FW_ZONES[$key2]}"

      policy="${FW_POLICIES["$src_zone->$dst_zone"]:-drop}"

      # Wildcard para interfaces y contador para nuevas conexiones
      ruleset+="    iifname \"$src_if*\" oifname \"$dst_if*\" counter $policy\n"
    done
  done

  ruleset+="  }\n"
  ruleset+="}\n"

  echo -e "$ruleset" | ip netns exec "$ns" nft -f -
  echo "✅ FW ${ns} zone-based activo (VLAN-aware + Counters)"
}