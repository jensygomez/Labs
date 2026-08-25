#!/bin/bash
echo -e "${C_BOLD}🏗️ INFRASTRUCTURE HEALTH (Internal Nodes)${C_RESET}"
echo -e "────────────────────────────────────────────────────────────"
printf " %-10s | %-4s | %-6s | %-6s | %-6s | %s\n" "NODE" "STAT" "LOAD" "RAM %" "DISK" "ROLE"
echo -e "────────────────────────────────────────────────────────────"

for node_info in "${INFRA_NODES[@]}"; do
    IFS=':' read -r name ip role <<< "$node_info"
    
    if ping -c 1 -W 1 "$ip" &>/dev/null; then
        status="${C_GREEN}UP${C_RESET}  "
        metrics=$(ssh -o ConnectTimeout=$SSH_TIMEOUT -o StrictHostKeyChecking=no -o BatchMode=yes ansible@$ip \
            "uptime | awk -F'load average:' '{print \$2}' | awk -F',' '{printf \"%.1f\", \$1}'; \
             free | awk '/Mem:/ {printf \"%d\", \$3/\$2*100}'; \
             df -h / | awk 'NR==2 {print \$5}'" 2>/dev/null)
        
        if [ $? -eq 0 ] && [ -n "$metrics" ]; then
            load=$(echo "$metrics" | cut -d' ' -f1)
            ram=$(echo "$metrics" | cut -d' ' -f2)
            disk=$(echo "$metrics" | cut -d' ' -f3)
            [ "$ram" -gt 80 ] 2>/dev/null && ram="${C_RED}${ram}%${C_RESET}" || ram="${ram}%"
            [ "${disk%\%}" -gt 80 ] 2>/dev/null && disk="${C_RED}${disk}${C_RESET}"
        else
            load="ERR"; ram="ERR"; disk="ERR"
        fi
    else
        status="${C_RED}DOWN${C_RESET}"
        load="---"; ram="---"; disk="---"
    fi
    printf " %-10s | %-10b | %-6s | %-6s | %-6s | %s\n" "$name" "$status" "$load" "$ram" "$disk" "$role"
done
