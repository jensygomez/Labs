#!/bin/bash
echo -e "${C_BOLD}🏗️ INFRASTRUCTURE HEALTH (Internal Nodes)${C_RESET}"
echo -e "────────────────────────────────────────────────────────────"
printf " %-10s | %-4s | %-6s | %-6s | %-6s | %s\n" "NODE" "STAT" "LOAD" "RAM %" "DISK" "ROLE"
echo -e "────────────────────────────────────────────────────────────"

for node_info in "${INFRA_NODES[@]}"; do
    IFS=':' read -r name ip role <<< "$node_info"
    
    # TRUCO: Usamos SSH como "ping". Si conecta, está UP. Si no, está DOWN.
    # Esto evita el error "Operation not permitted" de ping en contenedores rootless.
    # Combinamos el check de estado y las métricas en UNA sola llamada SSH para velocidad.
    metrics=$(ssh -o ConnectTimeout=$SSH_TIMEOUT -o StrictHostKeyChecking=no -o BatchMode=yes ansible@$ip \
        "echo 'UP'; \
         uptime | awk -F'load average:' '{print \$2}' | awk -F',' '{printf \"%.1f\", \$1}'; \
         free | awk '/Mem:/ {printf \"%d\", \$3/\$2*100}'; \
         df -h / | awk 'NR==2 {print \$5}'" 2>/dev/null)
    
    # La primera línea de la salida será "UP" si la conexión SSH tuvo éxito.
    if echo "$metrics" | head -n 1 | grep -q "UP"; then
        status="${C_GREEN}UP${C_RESET}  "
        
        # Extraemos las métricas de las líneas 2, 3 y 4
        load=$(echo "$metrics" | sed -n '2p')
        ram=$(echo "$metrics" | sed -n '3p')
        disk=$(echo "$metrics" | sed -n '4p')
        
        # Colorear métricas críticas (>80%)
        [ "$ram" -gt 80 ] 2>/dev/null && ram="${C_RED}${ram}%${C_RESET}" || ram="${ram}%"
        [ "${disk%\%}" -gt 80 ] 2>/dev/null && disk="${C_RED}${disk}${C_RESET}"
    else
        status="${C_RED}DOWN${C_RESET}"
        load="---"; ram="---"; disk="---"
    fi
    
    printf " %-10s | %-10b | %-6s | %-6s | %-6s | %s\n" "$name" "$status" "$load" "$ram" "$disk" "$role"
done
