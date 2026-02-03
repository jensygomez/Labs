#!/bin/bash
# network-engine/lib/firewall.sh

ensure_firewall() {
  local ns="$1"
  echo "🔒 Configurando FW en $ns"

  # 1. Validación de existencia del Namespace
  ns_exists "$ns" || { echo "❌ Namespace $ns no existe"; return 1; }

  # 2. Limpieza de reglas previas
  ip netns exec "$ns" nft delete table inet "fw_${ns}" 2>/dev/null || true

  # 3. Extracción segura de reglas (usando llaves y comillas dobles)
  # Esto evita el error de "subscrito incorreto" con nombres como EDGE-1
  local input_rules="${FW_RULES["${ns}"]:-}"

  # 4. Construcción del Ruleset (nftables)
  local ruleset=""
  ruleset+="table inet fw_${ns} {\n"
  
  # Cadena INPUT: Controla tráfico HACIA el router
  ruleset+="  chain input {\n"
  ruleset+="    type filter hook input priority 0; policy drop;\n"
  ruleset+="    iifname \"lo\" accept\n"
  ruleset+="    ct state established,related counter accept\n"
  [[ -n "$input_rules" ]] && ruleset+="    $input_rules\n"
  ruleset+="  }\n\n"

  # Cadena FORWARD: Controla tráfico QUE PASA por el router (Zonas)
  ruleset+="  chain forward {\n"
  ruleset+="    type filter hook forward priority 0; policy drop;\n"
  ruleset+="    ct state established,related counter accept\n"

  # Iterar sobre las zonas definidas para este namespace
  for key in "${!FW_ZONES[@]}"; do
    IFS=":" read -r src_ns src_if <<< "$key"
    [[ "$src_ns" != "$ns" ]] && continue
    
    local src_zone="${FW_ZONES["${key}"]}"

    for key2 in "${!FW_ZONES[@]}"; do
      IFS=":" read -r dst_ns dst_if <<< "$key2"
      [[ "$dst_ns" != "$ns" ]] && continue
      
      local dst_zone="${FW_ZONES["${key2}"]}"
      local policy_key="${src_zone}->${dst_zone}"
      local policy="${FW_POLICIES["${policy_key}"]:-drop}"

      # Aplicamos la regla basada en interfaces físicas o VLANs (wildcard *)
      ruleset+="    iifname \"$src_if*\" oifname \"$dst_if*\" counter $policy\n"
    done
  done

  ruleset+="  }\n"
  ruleset+="}\n"

  # 5. Aplicación atómica de las reglas
  echo -e "$ruleset" | ip netns exec "$ns" nft -f -
  echo "✅ FW ${ns} zone-based activo (VLAN-aware + Counters)"
}