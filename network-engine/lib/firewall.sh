#!/bin/bash
# network-engine/lib/firewall.sh

ensure_firewall() {
  local ns="$1"
  #echo "🔒 Configurando FW en $ns"

  ns_exists "$ns" || { echo "❌ Namespace $ns no existe"; return 1; }

  # 1. Limpiar tabla
  ip netns exec "$ns" nft delete table inet "fw_${ns}" 2>/dev/null || true

  # 2. Extracción Ultra-Segura de Reglas
  # Usamos una variable intermedia para evitar que Bash parsee el guion en $ns
  local input_rules=""
  local index="$ns"

  #echo "DEBUG: ns = $ns"
  #echo "DEBUG: index = $index"
  #echo "DEBUG: Todas las claves de FW_RULES:"
  for key in "${!FW_RULES[@]}"; do
    echo "  '$key' -> '${FW_RULES[$key]}'"
  done
  input_rules="${FW_RULES["$index"]:-}"

  local ruleset=""
  ruleset+="table inet fw_${ns} {\n"
  
  ruleset+="  chain input {\n"
  ruleset+="    type filter hook input priority 0; policy drop;\n"
  ruleset+="    iifname \"lo\" accept\n"
  ruleset+="    ct state established,related counter accept\n"
  [[ -n "$input_rules" ]] && ruleset+="    $input_rules\n"
  ruleset+="  }\n\n"

  ruleset+="  chain forward {\n"
  ruleset+="    type filter hook forward priority 0; policy drop;\n"
  ruleset+="    ct state established,related counter accept\n"

  # Iterar sobre las llaves de zonas
  for k in "${!FW_ZONES[@]}"; do
    # Usamos una variable de limpieza para el split
    local current_key="$k"
    IFS=":" read -r src_ns src_if <<< "$current_key"
    
    [[ "$src_ns" != "$ns" ]] && continue
    
    local src_zone="${FW_ZONES["$current_key"]}"

    for k2 in "${!FW_ZONES[@]}"; do
      local target_key="$k2"
      IFS=":" read -r dst_ns dst_if <<< "$target_key"
      [[ "$dst_ns" != "$ns" ]] && continue
      
      local dst_zone="${FW_ZONES["$target_key"]}"
      local p_key="${src_zone}->${dst_zone}"
      local policy="${FW_POLICIES["$p_key"]:-drop}"

      ruleset+="    iifname \"$src_if*\" oifname \"$dst_if*\" counter $policy\n"
    done
  done

  ruleset+="  }\n"
  ruleset+="}\n"

  #echo -e "$ruleset" | ip netns exec "$ns" nft -f -
  #echo "✅ FW ${ns} zone-based activo (VLAN-aware + Counters)"
}