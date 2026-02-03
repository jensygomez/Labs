#!/bin/bash
# network-engine/lib/firewall.sh
ensure_firewall() {
  local ns="$1"
  echo "🔒 Configurando FW en $ns"

  ns_exists "$ns" || { echo "❌ Namespace $ns no existe"; return 1; }

  # Eliminamos tabla previa si existe
  ip netns exec "$ns" nft delete table inet "fw_${ns}" 2>/dev/null || true

  local ruleset=""
  # FIX 1: Comillas en el índice para evitar que CORE-ADM sea visto como resta
  local input_rules="${FW_RULES["$ns"]:-}"

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

  # Iterar sobre las zonas definidas
  for key in "${!FW_ZONES[@]}"; do
    IFS=":" read -r src_ns src_if <<< "$key"
    [[ "$src_ns" != "$ns" ]] && continue
    # FIX 2: Comillas en el índice $key
    src_zone="${FW_ZONES["$key"]}"

    for key2 in "${!FW_ZONES[@]}"; do
      IFS=":" read -r dst_ns dst_if <<< "$key2"
      [[ "$dst_ns" != "$ns" ]] && continue
      # FIX 3: Comillas en el índice $key2
      dst_zone="${FW_ZONES["$key2"]}"

      # FIX 4: Comillas en el índice de la política
      policy="${FW_POLICIES["$src_zone->$dst_zone"]:-drop}"

      # Aplicar regla con contador
      ruleset+="    iifname \"$src_if*\" oifname \"$dst_if*\" counter $policy\n"
    done
  done

  ruleset+="  }\n"
  ruleset+="}\n"

  # Aplicar el conjunto de reglas
  echo -e "$ruleset" | ip netns exec "$ns" nft -f -
  echo "✅ FW ${ns} zone-based activo (VLAN-aware + Counters)"
}