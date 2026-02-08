#!/bin/bash
# network-engine/lib/firewall.sh
ensure_firewall() {
  local ns="$1"
  echo "🔒 Configurando FW en $ns"

  ns_exists "$ns" || { "❌ Namespace $ns no existe"; return 1; }

  # 1. Limpiar tabla
  ip netns exec "$ns" nft delete table inet "fw_${ns}" 2>/dev/null || true

  # 2. Extracción de reglas
  local input_rules=""
  local index="$ns"

  for key in "${!FW_RULES[@]}"; do
    "FW_RULE: '$key' -> '${FW_RULES[$key]}'"
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

  for k in "${!FW_ZONES[@]}"; do
    IFS=":" read -r src_ns src_if <<< "$k"
    [[ "$src_ns" != "$ns" ]] && continue
    local src_zone="${FW_ZONES[$k]}"

    for k2 in "${!FW_ZONES[@]}"; do
      IFS=":" read -r dst_ns dst_if <<< "$k2"
      [[ "$dst_ns" != "$ns" ]] && continue
      local dst_zone="${FW_ZONES[$k2]}"
      local p_key="${src_zone}->${dst_zone}"
      local policy="${FW_POLICIES[$p_key]:-drop}"

      ruleset+="    iifname \"$src_if*\" oifname \"$dst_if*\" counter $policy\n"
    done
  done

  # Reglas forward adicionales específicas (DESPUÉS del bucle de zonas)
  local forward_rules="${FW_FORWARD["$ns"]:-}"
  if [[ -n "$forward_rules" ]]; then
    ruleset+="    $forward_rules\n"
  fi

  ruleset+="  }\n"
  ruleset+="}\n"

  # ESTE SÍ DEBE EJECUTARSE
  echo -e "$ruleset" | ip netns exec "$ns" nft -f -

  "✅ FW ${ns} zone-based activo"
  return 0
}